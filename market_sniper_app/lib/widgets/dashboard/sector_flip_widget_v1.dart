import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../ui/tokens/dashboard_spacing.dart';
import 'breathing_status_accent.dart';

class SectorFlipWidgetV1 extends StatefulWidget {
  const SectorFlipWidgetV1({super.key});

  @override
  State<SectorFlipWidgetV1> createState() => _SectorFlipWidgetV1State();
}

class _SectorFlipWidgetV1State extends State<SectorFlipWidgetV1>
    with TickerProviderStateMixin {
  // Flip State
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;

  // Candle State
  late AnimationController _glowController;
  late Animation<double> _glowAnimation; // Breathing
  late Timer _directionTimer;
  bool _directionUp = true; 

  // Leader State (V3 Polish)
  String _leaderTicker = "";
  int _leaderVersion = 0; // For pulse keys

  // Replay State (V1.1)
  final List<_SectorFrame> _frames = [];
  int _replayIndex = 0; // 0 = Current
  bool _isReplayMode = false;
  // Buffer limit: 13 frames (60m @ 5m snap)

  // Data State
  late List<_SectorModel> _sectors;

  // Sentinel RT State (V0)
  // ignore: unused_field
  String? _sentinelMessage;
  Timer? _sentinelClearTimer;
  String? _prevLeaderTicker;
  
   // Source Tag
  final String _sourceTag = "HF04.RESTORE";

  // Shimmer State (V2 Ambient)
  late AnimationController _shimmerController;
  late Timer _shimmerTimer;

  @override
  void initState() {
    super.initState();

    // Data Init
    _sectors = [
      _SectorModel("TECH", "XLK", 72),
      _SectorModel("FINANCIALS", "XLF", 55),
      _SectorModel("ENERGY", "XLE", 41),
      _SectorModel("HEALTH", "XLV", 33),
      _SectorModel("INDUSTRIALS", "XLI", 25),
    ];
    // Init leader state without triggering events
    _prevLeaderTicker = _sectors.first.ticker;
    _updateLeaderState(silent: true);

    // Seed Synthetic Frames immediately (Robustness)
    _seedSyntheticFrames();

    // Flip Animation (300ms)
    _flipController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));

    // Glow Animation (2s in, 2s out loop)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Shimmer (Ambient Liveness)
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    // Trigger every ~8s
    _shimmerTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (mounted && _isFront) { // Only shimmer if front is visible
            _shimmerController.forward(from: 0);
        }
    });

    // Direction/Data Refresh Timer (15s)
    _directionTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
         _loadFramesFromPulseArtifacts();
         setState(() {
           _directionUp = !_directionUp; 
         });
      }
    });
  }
  
  void _seedSyntheticFrames() {
     if (_frames.isNotEmpty) return;
     
     final now = DateTime.now().toUtc();
     // Frame 0: Current
     _frames.add(_SectorFrame(now, _sectors.map((s) => _SectorRow(s.name, s.ticker, s.volumePct)).toList()));
     
     // Frame 1: -5m (Synthetic Variance)
     _frames.add(_SectorFrame(
         now.subtract(const Duration(minutes: 5)), 
         _sectors.map((s) => _SectorRow(s.name, s.ticker, (s.volumePct * 0.9).round())).toList()
     ));
  }
  
  @override
  void dispose() {
    _directionTimer.cancel();
    _shimmerTimer.cancel();
    _sentinelClearTimer?.cancel();
    _flipController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _loadFramesFromPulseArtifacts() {
     // Placeholder: If fetch fails, we retain synthetic history
     // Real implementation would http.get /dashboard here
     if (_frames.isEmpty) _seedSyntheticFrames();
  }
  
  void _updateLeaderState({bool silent = false}) {
     if (_sectors.isEmpty) return;
     
     // Find leader (max volume)
     final leader = _sectors.reduce((curr, next) => curr.volumePct > next.volumePct ? curr : next);
     
     if (leader.ticker != _leaderTicker) {
         if (mounted) {
             setState(() {
                 _leaderTicker = leader.ticker;
                 _leaderVersion++;
             });
         }
     }
  }

  void _finalizeFrame(DateTime nowUtc) {
    // Shared finish logic: Snapshot to frames, update leader
    // Deep copy current rows
    final frameRows = _sectors.map((s) => _SectorRow(s.name, s.ticker, s.volumePct)).toList();
    
    // Sentinel Analysis BEFORE insertion (using previous state vs new state)
    _analyzeSentinelEvents(frameRows, nowUtc);
    
    _frames.insert(0, _SectorFrame(nowUtc, frameRows));
    if (_frames.length > 13) _frames.removeLast();
    
    // If not replaying, keep index 0
    if (!_isReplayMode) {
      _replayIndex = 0;
    }
    
    _updateLeaderState(); 
  }

  void _analyzeSentinelEvents(List<_SectorRow> currentRows, DateTime nowUtc) {
     if (currentRows.isEmpty) return;
     
     final currentLeader = currentRows.first;
     final String timeStr = _formatEt(nowUtc);
     bool eventTriggered = false;
     String? newMessage;
     
     // 1. Leader Change Detection
     if (_prevLeaderTicker != null && currentLeader.ticker != _prevLeaderTicker) {
         newMessage = "Leader change · $timeStr";
         eventTriggered = true;
     }
     
     // 2. Volume Spike Detection
     if (!eventTriggered && _frames.length >= 3) {
         double baselineSum = 0;
         for (int i = 0; i < 3; i++) {
             if (_frames[i].rows.isNotEmpty) {
                baselineSum += _frames[i].rows.first.volumePct;
             }
         }
         final double baseline = baselineSum / 3.0;
         
         // Threshold: 25% increase (1.25x)
         if (currentLeader.volumePct > baseline * 1.25 && baseline > 10) {
             newMessage = "Volume spike · $timeStr";
             eventTriggered = true;
         }
     }
     
     if (eventTriggered && newMessage != null) {
         _sentinelMessage = newMessage;
         
         // Visual Pulse
         _glowController.forward(from: 0.8); // Quick flash
         
         // Auto-Clear Timer
         _sentinelClearTimer?.cancel();
         _sentinelClearTimer = Timer(const Duration(seconds: 12), () {
             if (mounted) {
                 setState(() { _sentinelMessage = null; });
             }
         });
     }
     
     // Update prev ref for next time
     _prevLeaderTicker = currentLeader.ticker;
  }
  
  void _toggleFlip() {
      if (mounted) {
          setState(() {
             _isFront = !_isFront; 
             if (_isFront) {
                 _flipController.reverse();
             } else {
                 _flipController.forward();
             }
          });
      }
  }

  @override
  Widget build(BuildContext context) {
      return AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
              final angle = _flipAnimation.value * 3.14159;
              final isFrontVisible = angle < 1.57; // 90 deg
              
              return Transform(
                  transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective
                      ..rotateY(angle),
                  alignment: Alignment.center,
                  child: isFrontVisible 
                     ? _buildFrontFace()
                     : Transform(
                         alignment: Alignment.center,
                         transform: Matrix4.identity()..rotateY(3.14159), // Mirror back
                         child: _buildBackFace()
                     )
              );
          }
      );
  }

  Widget _buildFrontFace() {
    Color upColor = AppColors.marketBull;
    Color downColor = AppColors.marketBear;
    bool leftActive = _directionUp;
    bool rightActive = !_directionUp;

    return Container(
      margin: const EdgeInsets.only(bottom: DashboardSpacing.gap),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(DashboardSpacing.cornerRadius),
        border: Border.all(color: AppColors.borderSubtle.withOpacity( 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity( 0.26),
            blurRadius: 4,
            offset: const Offset(0, 2)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                  Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Row(
                       children: [
                           Text("VOLUME INTELLIGENCE", 
                             style: AppTypography.title(context).copyWith(
                               letterSpacing: 0.6,
                               fontSize: 14 
                             )
                           ),
                           const SizedBox(width: 6),
                           BreathingStatusAccent(
                               color: _directionUp ? AppColors.marketBull : AppColors.marketBear,
                               active: true, 
                           ),
                       ]
                    ),
                    const SizedBox(height: 4), // Micro-gap
                     // Dynamic Subcopy with Future Override
                     if (_timelineValue > 4.0)
                        Row(
                            children: [
                                Text("Forward Context", 
                                   style: AppTypography.caption(context).copyWith(
                                       color: AppColors.textPrimary
                                   )
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                    onTap: _showProjectionModal,
                                    child: const Icon(Icons.help_outline, size: 12, color: AppColors.textDisabled)
                                )
                            ]
                        )
                     else
                        Text(_isReplayMode ? "Sector Volume • Replay Enabled" : "Sector Volume",
                           style: AppTypography.caption(context).copyWith(
                               color: AppColors.textSecondary.withOpacity(0.75)
                           )
                        ),
                    
                    // Sentinel Message
                    if (_sentinelMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(_sentinelMessage!,
                          style: AppTypography.caption(context).copyWith(
                             fontSize: 9, 
                             color: AppColors.neonCyan.withOpacity(0.9),
                             fontWeight: FontWeight.bold
                          )
                        ),
                      )
                 ]
              ),
              
              // ... Right Cluster code remains ... 
              Row(
                children: [
                   // Candles Animation
                   AnimatedBuilder(
                     animation: _glowAnimation,
                     builder: (context, _) {
                       return Row(children: [
                          _buildCandle(active: leftActive, color: upColor, glow: _glowAnimation.value),
                          const SizedBox(width: 4),
                          _buildCandle(active: rightActive, color: downColor, glow: _glowAnimation.value),
                       ]);
                     }
                   ),
                   const SizedBox(width: 8),
                   
                   // Leader Ticker
                   AnimatedSwitcher(
                     duration: const Duration(milliseconds: 200),
                     transitionBuilder: (Widget child, Animation<double> animation) {
                       return FadeTransition(opacity: animation, child: child);
                     },
                     child: Text(_leaderTicker, 
                       key: ValueKey<String>(_leaderTicker),
                       style: GoogleFonts.robotoMono(
                         color: AppColors.textPrimary,
                         fontSize: 11,
                         fontWeight: FontWeight.bold
                       )
                     ),
                   ),
                   const SizedBox(width: 8),

                   // Flip Icon
                   GestureDetector(
                     onTap: _toggleFlip,
                     child: const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary)
                   )
                ],
              )
            ],
          ),
          
          const SizedBox(height: 12),
          
          // FUTURE MODE: Replace List with Badge
          if (_timelineValue > 4.0)
             Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                     border: Border.all(color: AppColors.borderSubtle, width: 1, style: BorderStyle.solid),
                     borderRadius: BorderRadius.circular(8),
                     color: AppColors.surface2.withOpacity(0.3)
                 ),
                 child: Column(
                     children: [
                         Icon(Icons.auto_graph_outlined, size: 24, color: AppColors.textDisabled),
                         const SizedBox(height: 8),
                         Text("PROBABILISTIC CONTEXT\n(CALIBRATING)",
                             textAlign: TextAlign.center,
                             style: GoogleFonts.robotoMono(
                                 fontSize: 10,
                                 color: AppColors.textDisabled,
                                 fontWeight: FontWeight.bold,
                                 letterSpacing: 1.2
                             )
                         ),
                         const SizedBox(height: 4),
                         Text("Not enough historical similarity > 85% found.",
                             textAlign: TextAlign.center,
                             style: GoogleFonts.inter(
                                 fontSize: 10,
                                 color: AppColors.textDisabled.withOpacity(0.7),
                                 fontStyle: FontStyle.italic
                             )
                         ),
                     ]
                 ),
             )
          else
             // Sector List (Replay Logic)
             ...(_isReplayMode && _frames.isNotEmpty && _replayIndex < _frames.length
                ? _frames[_replayIndex].rows.take(4).map((r) => _buildSectorRowFromData(r)).toList()
                : _sectors.take(4).map((s) => _buildSectorRow(s)).toList()),

          // Scrubber (Always Shown)
          const SizedBox(height: 12),
          _buildScrubber(),
          
        ],
      )
    );
  }

  void _showProjectionModal() {
      showDialog(
          context: context, 
          builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface1,
              title: Text("Future Lane (Beta)", style: GoogleFonts.sora(color: AppColors.textPrimary, fontSize: 14)),
              content: Text(
                  "This lane generates a forward context frame using historical similarity once projection evidence is available. Until then, it remains calibrating.",
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)
              ),
              actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("CLOSE", style: GoogleFonts.robotoMono(color: AppColors.neonCyan))
                  )
              ]
          )
      );
  }

  Widget _buildCandle({required bool active, required Color color, required double glow}) {
    // Ramp density: 0.55 -> 0.95 based on glow
    final double opacity = 0.55 + (0.40 * glow);
    final Color bodyColor = active 
        ? color.withOpacity( opacity)
        : AppColors.textDisabled.withOpacity( 0.3);

    // Wicks slightly dimmer
    final Color wickColor = active
        ? color.withOpacity( opacity * 0.8) 
        : AppColors.textDisabled.withOpacity( 0.2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Wick
        Container(width: 1, height: 3, color: wickColor),
        // Body
        Container(
          width: 4, height: 10,
          decoration: BoxDecoration(
            color: bodyColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: active ? [
              BoxShadow(
                 color: color.withOpacity( 0.6 * glow),
                 blurRadius: 4 + (4 * glow), // 4 -> 8
                 spreadRadius: 0.5 + (1.5 * glow) // 0.5 -> 2.0
              )
            ] : []
          ),
        ),
        // Bottom Wick
        Container(width: 1, height: 3, color: wickColor),
      ],
    );
  }

  Widget _buildSectorRow(_SectorModel sector) {
    // Baseline Mock (For Delta Chip)
    // In real implementation, this comes from 'open' snapshot.
    double? baseline;
    if (_frames.length > 5 && _frames.last.rows.isNotEmpty) {
       try {
           final oldRow = _frames.last.rows.firstWhere((r) => r.ticker == sector.ticker);
           baseline = oldRow.volumePct.toDouble();
       } catch (_) {}
    }

    // Delta Calc
    String deltaText = "—";
    Color deltaColor = AppColors.textDisabled;
    if (baseline != null) {
        final diff = sector.volumePct - baseline;
        if (diff != 0) {
            final sign = diff > 0 ? "+" : "";
            deltaText = "$sign${diff.toInt()} pts"; 
            deltaColor = diff > 0 ? AppColors.marketBull : AppColors.marketBear;
        } else {
            deltaText = "FLAT";
        }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0), // Compact Spacing (was 8)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Name + Ticker
          SizedBox(
            width: 100,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: sector.name, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                  TextSpan(text: "\n${sector.ticker}", style: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 9)),
                ]
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(width: 8),

          // Delta Chip
          Container(
             width: 50,
             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
             decoration: BoxDecoration(
                 color: AppColors.surface2,
                 borderRadius: BorderRadius.circular(4),
                 border: Border.all(color: AppColors.borderSubtle.withOpacity(0.5))
             ),
             child: Text(
                 deltaText,
                 textAlign: TextAlign.center,
                 style: GoogleFonts.robotoMono(
                     fontSize: 9, 
                     color: deltaColor,
                     fontWeight: FontWeight.w500
                 )
             ),
          ),

          const SizedBox(width: 8),

          // Bar
          Expanded(
            child: Container(
              height: 8, // Compact Height (was 9)
              decoration: BoxDecoration(
                color: AppColors.textDisabled.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2)
              ),
              child: Stack(
                children: [
                   // Base Bar with Fade
                   FractionallySizedBox(
                     widthFactor: sector.volumePct / 100.0,
                     child: ClipRRect( 
                       borderRadius: BorderRadius.circular(1),
                       child: Stack(
                         fit: StackFit.expand, // Force children to fill strict FractionallySizedBox constraints
                         children: [
                           // 1. Base Gradient Fill
                           Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                      AppColors.neonCyan.withOpacity(0.7), 
                                      AppColors.neonCyan,
                                      AppColors.neonCyan.withOpacity(0.0) 
                                  ],
                                  stops: const [0.0, 0.85, 1.0],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight
                                ),
                              ),
                           ),
                           
                           // 2. Welcome Slogan Shimmer (Adapted)
                           // Technique: ShaderMask overlay on a white container (additive blend)
                           AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, child) {
                                    final double t = _shimmerController.value;
                                    // Slogan Logic: start = (t * 1.8 - 0.4).clamp(0.0, 1.0);
                                    // For bar, we want it to travel full width.
                                    // 0 -> 1 is fine if we use simpler range or stick to exact.
                                    // Using exact Slogan math for "Motion Language" consistency:
                                    final double start = (t * 1.8 - 0.4).clamp(0.0, 1.0); 
                                    final double end = (start + 0.15).clamp(0.0, 1.0); // Slightly wider for bar? Slogan was 0.10
                                    
                                    return ShaderMask(
                                        blendMode: BlendMode.srcIn, // Mask the child container
                                        shaderCallback: (Rect bounds) {
                                            return LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                    Colors.transparent,
                                                    AppColors.neonCyan.withOpacity(0.0), // Cyan base 0
                                                    AppColors.neonCyan.withOpacity(0.5), // Cyan peak
                                                    AppColors.neonCyan.withOpacity(0.0), // Cyan base 0
                                                    Colors.transparent
                                                ],
                                                stops: [
                                                    0.0,
                                                    start,
                                                    (start + end) / 2,
                                                    end,
                                                    1.0
                                                ]
                                            ).createShader(bounds);
                                        },
                                        // The child here is the "Ink" to be masked. 
                                        // We want a white/silver ink that gets masked by the gradient alpha.
                                        child: Container(
                                            color: AppColors.textPrimary.withOpacity(0.4) // Base intensity
                                        ),
                                    );
                                }
                           )
                         ],
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
          
          // Pct
          SizedBox(
            width: 32,
            child: Text("${sector.volumePct}", 
              textAlign: TextAlign.end,
              style: GoogleFonts.robotoMono(color: AppColors.textSecondary, fontSize: 10)
            ),
          )
        ],
      ),
    );
  }

  // --- BACK FACE ---
  Widget _buildBackFace() {
    // V2 Data Model: Optional, nullable-safe.
    // In future, this comes from providers. Today, it fails gracefully to "Unavailable".
    final VolumeIntelBackData? data = null; // Forced unavailable for now

    // Safe Defaults
    final String leaderSymbol = _leaderTicker.isNotEmpty ? _leaderTicker : "—";
    final List<String> drivers = data?.leaderReasonBullets ?? [];
    final bool hasDrivers = drivers.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DashboardSpacing.gap),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(DashboardSpacing.cornerRadius),
        border: Border.all(color: AppColors.borderSubtle.withOpacity( 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity( 0.26),
            blurRadius: 4,
            offset: const Offset(0, 2)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Header
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                      Text("WHY $leaderSymbol LEADS", 
                        style: AppTypography.title(context).copyWith(
                            letterSpacing: 0.6,
                            fontSize: 14,
                            color: AppColors.marketBull
                        )
                      ),
                      const SizedBox(height: 4),
                       Text("Replay Enabled • Context View", 
                        style: AppTypography.caption(context).copyWith(
                           color: AppColors.textSecondary.withOpacity(0.75)
                        )
                      ),
                 ],
               ),
               GestureDetector(
                 onTap: _toggleFlip,
                 child: Container(
                   padding: const EdgeInsets.all(4), // Hitbox
                   child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary)
                 )
               )
             ],
           ),
           
           const SizedBox(height: 12),
           
           // SECTION: KEY DRIVERS
           Text("KEY DRIVERS", style: GoogleFonts.robotoMono(fontSize: 10, color: AppColors.textDisabled, fontWeight: FontWeight.bold)),
           const SizedBox(height: 6),
           if (hasDrivers)
              ...drivers.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4), 
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          const Text("• ", style: TextStyle(color: AppColors.marketBull, fontSize: 10)),
                          Expanded(child: Text(d, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)))
                      ]
                  )
              ))
           else
              _buildUnavailablePlaceholder("Context unavailable"),

           const SizedBox(height: 12),

           // SECTION: STATISTICS
           Text("LEADER STATS", style: GoogleFonts.robotoMono(fontSize: 10, color: AppColors.textDisabled, fontWeight: FontWeight.bold)),
           const SizedBox(height: 6),
           Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                   _buildStatItem("Stability", data?.stabilityMinutes != null ? "${data!.stabilityMinutes}m" : "—"),
                   _buildStatItem("Accel", data?.accelPts != null ? "+${data!.accelPts}" : "—"),
                   _buildStatItem("Gap vs #2", data?.gapPts != null ? "+${data!.gapPts}" : "—"),
               ],
           ),

           const SizedBox(height: 12),

           // SECTION: TOP CONTRIBUTORS
           Text("TOP CONTRIBUTORS", style: GoogleFonts.robotoMono(fontSize: 10, color: AppColors.textDisabled, fontWeight: FontWeight.bold)),
           const SizedBox(height: 6),
           if (data?.contributors != null && data!.contributors!.isNotEmpty)
               ...data.contributors!.map((c) => Padding(
                   padding: const EdgeInsets.only(bottom: 4),
                   child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                           Text(c.symbol, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                           Text("${c.contributionPct}%", style: GoogleFonts.robotoMono(color: AppColors.marketBull, fontSize: 11))
                       ],
                   )
               ))
           else
               _buildUnavailablePlaceholder("Contributors unavailable"),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textDisabled)),
              Text(value, style: GoogleFonts.robotoMono(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold))
          ],
      );
  }

  Widget _buildUnavailablePlaceholder(String text) {
      return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.surface2.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4)
          ),
          child: Text(text, 
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDisabled.withOpacity(0.7), fontStyle: FontStyle.italic)
          ),
      );
  }
  
  // Keep Scrubber logic, etc...
  // Timeline State
  double _timelineValue = 4.0; // 0..8, 4=NOW

  void _onTimelineChanged(double val) {
     setState(() {
         _timelineValue = val;
         
         // Logic: 0..3 = Past (-60, -45, -30, -15)
         // 4 = Now
         // 5..8 = Future (+15, +30, +45, +60)
         
         if (val < 4.0) {
             // PAST: Replay Mode
             _isReplayMode = true;
             
             // Calc target offset index
             // 4=0m, 3=15m, 2=30m, 1=45m, 0=60m
             final int minutesAgo = ((4 - val) * 15).toInt();
             final DateTime now = DateTime.now().toUtc();
             final DateTime target = now.subtract(Duration(minutes: minutesAgo));
             
             // Find closed frame
             int bestIndex = 0;
             int minDiff = 999999;
             
             for (int i=0; i<_frames.length; i++) {
                 final diff = _frames[i].asOfUtc.difference(target).inSeconds.abs();
                 if (diff < minDiff) {
                     minDiff = diff;
                     bestIndex = i;
                 }
             }
             _replayIndex = bestIndex;
             
         } else if (val > 4.0) {
             // FUTURE: Show Current Frame but activate Future Badge
             _isReplayMode = false;
             // Don't change _replayIndex (keep it at max/live)
         } else {
             // NOW: Live
             _isReplayMode = false;
         }
     });
  }

  Widget _buildScrubber() {
    // Labels for the 9 points
    final List<String> labels = [
        "-60m", "-45m", "-30m", "-15m", "NOW", "+15m", "+30m", "+45m", "+60m"
    ];
    
    final int index = _timelineValue.round();
    final String label = (index >= 0 && index < labels.length) ? labels[index] : "—";
    
    final bool isFuture = _timelineValue > 4.0;
    final bool isPast = _timelineValue < 4.0;
    
    Color activeColor = AppColors.marketBull;
    if (isFuture) activeColor = AppColors.textPrimary; // Neutral/Purple for future?
    if (isPast) activeColor = AppColors.neonCyan;

    return Column(
      children: [
        // Meta Row
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                 Text(label, 
                     style: GoogleFonts.robotoMono(
                         color: activeColor, 
                         fontSize: 10, 
                         fontWeight: FontWeight.bold
                     )
                 ),
                 
                 // Show "Calibrating" text if Future
                 if (isFuture)
                    Text("PROJECTION (CALIBRATING)",
                         style: GoogleFonts.robotoMono(
                             color: AppColors.textDisabled, 
                             fontSize: 9,
                             fontStyle: FontStyle.italic
                         )
                    )
                 else if (isPast)
                     Text("HISTORICAL CONTEXT",
                         style: GoogleFonts.robotoMono(
                             color: AppColors.textDisabled, 
                             fontSize: 9
                         )
                     )
                 else
                     Text("LIVE MARKET",
                          style: GoogleFonts.robotoMono(color: AppColors.marketBull, fontSize: 9)
                     ),
            ],
        ),
        
        // Slider
        SliderTheme(
            data: SliderThemeData(
                trackHeight: 2,
                activeTrackColor: activeColor.withOpacity(0.5),
                inactiveTrackColor: AppColors.borderSubtle,
                thumbColor: activeColor,
                overlayColor: activeColor.withOpacity(0.1),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                valueIndicatorTextStyle: GoogleFonts.robotoMono(fontSize: 10),
            ),
            child: Slider(
                value: _timelineValue,
                min: 0,
                max: 8,
                divisions: 8,
                onChanged: _onTimelineChanged,
            ),
        ),
        
        // Tick Marks (Visual Aid)
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10), // Align with slider padding approx
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(9, (i) {
                    final bool isCenter = i == 4;
                    return Container(
                        width: 2,
                        height: isCenter ? 6 : 4,
                        color: isCenter ? AppColors.textPrimary : AppColors.borderSubtle.withOpacity(0.5)
                    );
                })
            ),
        )
      ],
    );
  }
  
  int uniqueMaxIndex(int length) {
      if (length <= 1) return 0;
      return length - 1;
  }

  // Safe ET Formatter (UTC-5/4 approx or just raw UTC-5 for consistency)
  String _formatEt(DateTime utc) {
     final et = utc.subtract(const Duration(hours: 5));
     final h = et.hour.toString().padLeft(2, '0');
     final m = et.minute.toString().padLeft(2, '0');
     return "$h:$m ET";
  }

  Widget _buildSectorRowFromData(_SectorRow row) {
      // Adapter to use existing row builder logic with internal model
      return _buildSectorRow(_SectorModel(row.name, row.ticker, row.volumePct));
  }
}

class _SectorModel {
  final String name;
  final String ticker;
  final int volumePct;
  
  _SectorModel(this.name, this.ticker, this.volumePct);
}

// Replay Models
class _SectorFrame { 
    final DateTime asOfUtc; 
    final List<_SectorRow> rows; 
    _SectorFrame(this.asOfUtc, this.rows);
}

class _SectorRow {
    final String name;
    final String ticker;
    final int volumePct;
    _SectorRow(this.name, this.ticker, this.volumePct);
}

// Back Data Model (Optional/Nullable)
class VolumeIntelBackData {
    final String leaderSymbol;
    final List<String> leaderReasonBullets;
    final int? stabilityMinutes;
    final int? accelPts;
    final int? gapPts;
    final List<Contributor>? contributors;
    
    VolumeIntelBackData({
        required this.leaderSymbol,
        this.leaderReasonBullets = const [],
        this.stabilityMinutes,
        this.accelPts,
        this.gapPts,
        this.contributors
    });
}

class Contributor {
    final String symbol;
    final int contributionPct;
    Contributor(this.symbol, this.contributionPct);
}
