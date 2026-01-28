import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../ui/tokens/dashboard_spacing.dart';
import '../../models/regime_sentinel_model.dart';
import '../../utils/time_utils.dart';
import 'breathing_status_accent.dart';

// HF18: Local Model for Charting
class IntradayCandle {
  final String tUtc;
  final double o;
  final double h;
  final double l;
  final double c;
  final bool isGhost;

  IntradayCandle({
    required this.tUtc,
    required this.o,
    required this.h,
    required this.l,
    required this.c,
    required this.isGhost,
  });

  factory IntradayCandle.fromJson(Map<String, dynamic> json) {
    return IntradayCandle(
      tUtc: json['tUtc'] ?? "",
      o: (json['o'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
      l: (json['l'] as num).toDouble(),
      c: (json['c'] as num).toDouble(),
      isGhost: json['isGhost'] ?? false,
    );
  }
}

class ProjectionCoords {
  final double yMin;
  final double yMax;
  
  ProjectionCoords({required this.yMin, required this.yMax});
  
  factory ProjectionCoords.fromJson(Map<String, dynamic> json) {
    return ProjectionCoords(
      yMin: (json['yMin'] as num?)?.toDouble() ?? 0.0,
      yMax: (json['yMax'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class RegimeSentinelWidget extends StatefulWidget {
  const RegimeSentinelWidget({super.key});

  @override
  State<RegimeSentinelWidget> createState() => _RegimeSentinelWidgetState();
}

class _RegimeSentinelWidgetState extends State<RegimeSentinelWidget> with TickerProviderStateMixin {
  // Flip State
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;

  // Data State
  String _selectedIndex = "SPY"; // SPY, QQQ, DIA
  double _timelineValue = 0; // -4 to +4
  final double _timelineMax = 4;
  final double _timelineMin = -4;

  // 10:30 AM Gating State
  // 10:30 AM Gating State
  bool _isCalibrating = true; // Default true until fetched
  String? _calibrationMessage;
  Timer? _calibrationTimer;
  
  // HF18: Chart Data
  List<IntradayCandle> _pastCandles = [];
  List<IntradayCandle> _futureBase = [];
  List<IntradayCandle> _futureStress = [];
  ProjectionCoords? _coords;
  bool _isDemoData = false;
  
  // Candle Animation
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
        
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _checkCalibration();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _glowController.dispose();
    _calibrationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkCalibration() async {
     try {
       // HF18: Real Fetch
       final uri = Uri.parse('${AppConfig.apiBaseUrl}/projection/report?symbol=$_selectedIndex');
       final response = await http.get(uri);
       
       if (response.statusCode == 200) {
           final data = json.decode(response.body);
           final state = data['state'];
           final stateReasons = List<String>.from(data['stateReasons'] ?? []);
           
           final intraday = data['intraday'];
           final scenarios = data['scenarios'];
           
           List<IntradayCandle> past = [];
           if (intraday != null && intraday['pastCandles'] != null) {
              past = (intraday['pastCandles'] as List).map((x) => IntradayCandle.fromJson(x)).toList();
           }
           
           List<IntradayCandle> fBase = [];
           if (scenarios != null && scenarios['base'] != null && scenarios['base']['envelope'] != null) {
              final env = scenarios['base']['envelope'];
              if (env['candles'] != null) {
                  fBase = (env['candles'] as List).map((x) => IntradayCandle.fromJson(x)).toList();
              }
           }
           
           // Coords (from base scenario bounds)
           ProjectionCoords? coords;
           if (scenarios != null && scenarios['base'] != null && scenarios['base']['bounds'] != null) {
               coords = ProjectionCoords.fromJson(scenarios['base']['bounds']);
           }

           if (mounted) {
               setState(() {
                   _isCalibrating = (state == "CALIBRATING" || state == "INSUFFICIENT_DATA");
                   if (_isCalibrating) {
                       _calibrationMessage = "Orchestrator: $state (${stateReasons.join(', ')})";
                   } else {
                       _calibrationMessage = null;
                   }
                   
                   _pastCandles = past;
                   _futureBase = fBase;
                   _coords = coords;
                   _isDemoData = stateReasons.contains("DEMO_SERIES_ACTIVE");
               });
           }
       }
     } catch (e) {
        if (mounted) {
            setState(() {
                _isCalibrating = true; 
                _calibrationMessage = "Connection Error";
            });
        }
     }
  }

  bool _isFutureLocked() {
    final nowEt = TimeUtils.getNowEt(); 
    final time1030 = DateTime(nowEt.year, nowEt.month, nowEt.day, 10, 30);
    return nowEt.isBefore(time1030);
  }

  void _toggleFlip() {
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  void _onIndexChanged(String index) {
    setState(() {
        _selectedIndex = index;
        // Reset data to force refresh visualization
        _pastCandles = [];
        _futureBase = [];
    });
    _checkCalibration();
  }

  void _onTimelineChanged(double value) {
    if (value > 0 && _isFutureLocked()) {
      setState(() {
        _timelineValue = 0;
        _isCalibrating = true;
        _calibrationMessage = "Calibrating Volatility...";
      });
      _calibrationTimer?.cancel();
      _calibrationTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isCalibrating = false);
      });
    } else {
      setState(() {
        _timelineValue = value;
      });
    }
  }
  
  void _openFullscreen() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: _FullscreenChart(
           selectedIndex: _selectedIndex,
           timelineValue: _timelineValue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * pi;
        final isBack = _flipAnimation.value >= 0.5;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: isBack
              ? Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _buildBackFace(),
                )
              : _buildFrontFace(),
        );
      },
    );
  }

  Widget _buildFrontFace() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          GestureDetector(
             onTap: _openFullscreen,
             child: _buildChartArea(),
          ),
          const SizedBox(height: 12),
          _buildTimelineSlider(),
          if (_isCalibrating) 
             Padding(
               padding: const EdgeInsets.only(top: 8),
               child: Center(
                 child: Text(
                   _calibrationMessage ?? "",
                   style: AppTypography.caption(context).copyWith(color: AppColors.neonCyan),
                 ),
               ),
             ),
          const SizedBox(height: 8),
          _buildStatusChips(),
        ],
      ),
    );
  }

  Widget _buildBackFace() {
    return GestureDetector(
      onTap: _toggleFlip,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                _buildBackHeader(),
                const Divider(color: AppColors.borderSubtle),
                const SizedBox(height: 12),
                Text("EVIDENCE SUMMARY", style: AppTypography.label(context)),
                const SizedBox(height: 4),
                Text("Calibration in progress. No artifact available.", style: AppTypography.caption(context)),
                const SizedBox(height: 12),
                Text("MACRO CONTEXT", style: AppTypography.label(context)),
                const SizedBox(height: 4),
                Text("Data stream initializing...", style: AppTypography.caption(context)),
                const SizedBox(height: 20),
                Text("ENGINES ACTIVE", style: AppTypography.label(context)),
                const SizedBox(height: 8),
                Row(
                    children: [
                        const Icon(Icons.analytics, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text("Backtesting", style: AppTypography.caption(context)),
                        const SizedBox(width: 12),
                        const Icon(Icons.waves, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text("Pulse", style: AppTypography.caption(context)),
                    ],
                )
            ]
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
               // Title + Subtitle + Breathing Accent
               Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                       Row(
                           children: [
                               Text("REGIME SENTINEL", 
                                  style: AppTypography.title(context).copyWith(
                                    letterSpacing: 0.6,
                                    fontSize: 14 
                                  )
                               ),
                               const SizedBox(width: 6),
                               // Neutral Breathing Accent (Always Neutral for now)
                               const BreathingStatusAccent(
                                   color: AppColors.textDisabled, // Neutral
                                   active: true, // It breathes, but neutral color
                               ),
                           ]
                       ),
                       const SizedBox(height: 2),
                       Text("Index Regime", 
                           style: AppTypography.caption(context).copyWith(
                               color: AppColors.textSecondary.withOpacity(0.75)
                           )
                       ),
                   ]
               ),
               
               // Right Cluster: Candles + Info
               Row(
                   children: [
                       AnimatedBuilder(
                         animation: _glowAnimation,
                         builder: (context, _) {
                           return Row(children: [
                              _buildCandle(active: true, color: AppColors.textDisabled, glow: _glowAnimation.value * 0.5), // Neutral
                              const SizedBox(width: 4),
                              _buildCandle(active: true, color: AppColors.textDisabled, glow: _glowAnimation.value * 0.5), // Neutral
                           ]);
                         }
                       ),
                       const SizedBox(width: 8),
                       IconButton(
                         icon: const Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
                         onPressed: _toggleFlip,
                       ),
                   ]
               )
           ]
        ),
        
        const SizedBox(height: 12),
        
        // Selector Row (Moved Below)
        Row(
            children: [
                _buildIndexButton("SPY", _selectedIndex == "SPY"),
                const SizedBox(width: 4),
                _buildIndexButton("QQQ", _selectedIndex == "QQQ"),
                const SizedBox(width: 4),
                _buildIndexButton("DIA", _selectedIndex == "DIA"),
            ],
        ),
      ],
    );
  }
  
  Widget _buildBackHeader() {
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              Text("REGIME INTELLIGENCE", style: AppTypography.title(context)),
              const Icon(Icons.flip_to_front, size: 20, color: AppColors.textSecondary),
          ]
      );
  }

  Widget _buildIndexButton(String ticker, bool isSelected) {
    return GestureDetector(
      onTap: () => _onIndexChanged(ticker),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Adjusted for 3 buttons
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonCyan.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.neonCyan : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          ticker,
          style: AppTypography.label(context).copyWith(
            color: isSelected ? AppColors.neonCyan : AppColors.textSecondary,
             fontSize: 12, // Compact
          ),
        ),
      ),
    );
  }

  Widget _buildChartArea() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle.withOpacity(0.5)),
      ),
      child: Stack(
          children: [
              // Grid lines
              Positioned.fill(
                  child: CustomPaint(
                      painter: _GridPainter(),
                  )
              ),
              // Ghost Trace (Deterministic Calibrating Pattern) or Real Candles
              Positioned.fill(
                  child: CustomPaint(
                      painter: _isCalibrating || _pastCandles.isEmpty
                          ? _GhostTracePainter()
                          : _SeriesPainter(
                              past: _pastCandles,
                              future: _futureBase,
                              coords: _coords,
                              isFutureLocked: _isFutureLocked(),
                              timelineValue: _timelineValue
                            ),
                  )
              ),
              // Base Scenario (Ghost)
              if (_timelineValue > 0)
                  Positioned.fill(
                     child: Opacity(
                         opacity: 0.3,
                         child: Center(child: Text("BASE SCENARIO", style: AppTypography.caption(context))),
                     ),
                  ),
               // Stress Scenario (Ghost)
               if (_timelineValue > 0)
                  Positioned(
                      bottom: 10, right: 10,
                      child: Opacity(
                          opacity: 0.3,
                          child: Text("STRESS", style: AppTypography.caption(context).copyWith(color: AppColors.marketBear)),
                      )
                  ),
                // Center Label if 0
                if (_timelineValue == 0)
                    Center(child: Text("CURRENT REGIME", style: AppTypography.caption(context))),
          ],
      ),
    );
  }

  Widget _buildTimelineSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.borderSubtle,
            inactiveTrackColor: AppColors.surface2,
            thumbColor: AppColors.neonCyan,
            overlayColor: AppColors.neonCyan.withOpacity(0.2),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: _timelineValue,
            min: _timelineMin,
            max: _timelineMax,
            divisions: 8,
            onChanged: _onTimelineChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("-60m", style: AppTypography.caption(context)),
              Text("NOW", style: AppTypography.badge(context).copyWith(color: AppColors.neonCyan)),
              Text("+60m", style: _isFutureLocked() ? AppTypography.caption(context).copyWith(color: AppColors.textDisabled) : AppTypography.caption(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      children: [
        _buildChip("Probabilistic Context", true),
        if (_isDemoData) _buildChip("DEMO INTRADAY", true, color: AppColors.marketBear), // Distinctive
        _buildChip("Backtesting Engine", false),
      ],
    );
  }


  Widget _buildChip(String label, bool active, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? (color?.withOpacity(0.1) ?? AppColors.surface2) : AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(4),
        border: color != null ? Border.all(color: color, width: 0.5) : null,
      ),
      child: Text(
        label,
        style: AppTypography.caption(context).copyWith(
          color: color ?? (active ? AppColors.textSecondary : AppColors.textDisabled),
          fontSize: 10,
        ),
      ),
    );
  }
  
  Widget _buildCandle({required bool active, required Color color, required double glow}) {
    // Reused logic from SectorFlipWidgetV1
    final double opacity = 0.55 + (0.40 * glow);
    final Color bodyColor = active 
        ? color.withOpacity( opacity)
        : AppColors.textDisabled.withOpacity( 0.3);
    final Color wickColor = active
        ? color.withOpacity( opacity * 0.8) 
        : AppColors.textDisabled.withOpacity( 0.2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1, height: 3, color: wickColor),
        Container(
          width: 4, height: 10,
          decoration: BoxDecoration(
            color: bodyColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(width: 1, height: 3, color: wickColor),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
    @override
    void paint(Canvas canvas, Size size) {
        final paint = Paint()
            ..color = AppColors.borderSubtle.withOpacity(0.15) // Subtle
            ..strokeWidth = 1;
            
        // Horizontal lines
        for (double i = 0; i < size.height; i += 30) {
            canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
        }
        
         // Vertical lines
        for (double i = 0; i < size.width; i += 40) {
            canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
        }
    }
    
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GhostTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Deterministic Calibrating Pattern: Sine wave with decay
    final paint = Paint()
      ..color = AppColors.neonCyan.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerY = size.height / 2;
    
    path.moveTo(0, centerY);

    // Draw a deterministic "heartbeat" or "calibrating" sine wave
    for (double x = 0; x <= size.width; x++) {
       // Frequency varies slightly to look "alive" but is math-deterministic
       final normalizedX = x / size.width;
       final amplitude = 20.0 * (1 - normalizedX) * sin(normalizedX * pi * 8); 
       
       // Deterministic shape
       final y = centerY + amplitude;
       path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeriesPainter extends CustomPainter {
  final List<IntradayCandle> past;
  final List<IntradayCandle> future;
  final ProjectionCoords? coords;
  final bool isFutureLocked;
  final double timelineValue;

  _SeriesPainter({required this.past, required this.future, this.coords, required this.isFutureLocked, required this.timelineValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (coords == null || (past.isEmpty && future.isEmpty)) return;
    
    final paint = Paint()..strokeWidth = 1.0;
    
    // Normalize logic
    // Y: (price - min) / (max - min) * height (inverted)
    // X: equal spacing for now.
    
    final yMin = coords!.yMin;
    final yRange = coords!.yMax - yMin;
    if (yRange == 0) return;
    
    // Total slots: let's assume we render what we have.
    // If we want fixed horizon (e.g. 24 candles), we divide width by 24.
    final totalSlots = 24.0;
    final w = size.width / totalSlots;
    final h = size.height;
    
    // START DRAWING
    // 1. PAST
    for (int i = 0; i < past.length; i++) {
        _drawCandle(canvas, past[i], i.toDouble(), w, h, yMin, yRange, isGhost: false);
    }
    
    // 2. FUTURE (Base)
    // Only if not locked OR if timeline > 0 (showing future)
    // Wait, requirement: "Keep 10:30 gating logic intact (future lane locked before 10:30, but DEMO series should still exist—just not user-visible future)"
    // If locked, we don't draw future.
    if (!isFutureLocked || timelineValue > 0) {
         // Start X after past
         final startX = past.length;
         for (int i = 0; i < future.length; i++) {
             _drawCandle(canvas, future[i], startX + i.toDouble(), w, h, yMin, yRange, isGhost: true);
         }
    }
  }
  
  void _drawCandle(Canvas canvas, IntradayCandle c, double slotIndex, double w, double h, double yMin, double yRange, {required bool isGhost}) {
      final x = slotIndex * w;
      final cx = x + (w/2);
      
      double normalize(double p) => h - ((p - yMin) / yRange * h);
      
      final yO = normalize(c.o);
      final yC = normalize(c.c);
      final yH = normalize(c.h);
      final yL = normalize(c.l);
      
      final isBull = c.c >= c.o;
      final color = isBull ? AppColors.marketBull : AppColors.marketBear;
      
      final paint = Paint()
        ..color = isGhost ? color.withOpacity(0.3) : color
        ..style = PaintingStyle.fill;
        
      // Wick
      canvas.drawLine(
          Offset(cx, yH), 
          Offset(cx, yL), 
          paint..strokeWidth = 1
      );
      
      // Body
      final bodyTop = min(yO, yC);
      final bodyBot = max(yO, yC);
      final bodyHeight = max(1.0, bodyBot - bodyTop);
      
      canvas.drawRect(
          Rect.fromLTWH(x + 1, bodyTop, w - 2, bodyHeight), 
          paint..style = PaintingStyle.fill
      );
  }

  @override
  bool shouldRepaint(covariant _SeriesPainter old) => true;
}


class _FullscreenChart extends StatelessWidget {
   final String selectedIndex;
   final double timelineValue;
   
   const _FullscreenChart({required this.selectedIndex, required this.timelineValue});
   
   @override
   Widget build(BuildContext context) {
      return Container(
          width: double.infinity,
          height: 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
             color: AppColors.surface1,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: AppColors.neonCyan.withOpacity(0.5)),
          ),
          child: Column(
              children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Text("$selectedIndex • FULL DETAIL", style: AppTypography.title(context)),
                          IconButton(
                             icon: const Icon(Icons.close, color: AppColors.textSecondary),
                             onPressed: () => Navigator.pop(context),
                          )
                      ]
                  ),
                  const Divider(color: AppColors.borderSubtle),
                  Expanded(
                       child: Container(
                           decoration: BoxDecoration(
                               color: AppColors.bgPrimary,
                               borderRadius: BorderRadius.circular(8)
                           ),
                           child: CustomPaint(
                               painter: _GhostTracePainter(),
                               child: CustomPaint(
                                   painter: _GridPainter(),
                               ),
                           ),
                       )
                  ),
                  const SizedBox(height: 16),
                  Text("Expanded Analysis View", style: AppTypography.caption(context))
              ]
          )
      );
   }
}
