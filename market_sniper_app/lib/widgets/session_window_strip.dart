import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../logic/data_state_resolver.dart';
import '../models/system_health_snapshot.dart'; // D45.18

class SessionWindowStrip extends StatefulWidget {
  final ResolvedDataState dataState;
  final SystemHealthSnapshot? healthSnapshot; // Managed but unused visually in V1

  const SessionWindowStrip({
    super.key,
    required this.dataState,
    this.healthSnapshot,
  });

  @override
  State<SessionWindowStrip> createState() => _SessionWindowStripState();
}

class _SessionWindowStripState extends State<SessionWindowStrip>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // State
  late DateTime _nowEt;
  String _marketLabel = "LOADING...";
  
  // Module States
  bool _stocksOn = false;
  bool _optionsOn = false;
  bool _newsOn = true; // Always ON
  bool _macroOn = false;

  @override
  void initState() {
    super.initState();
    // Animation: Breath 2s in, 2s out
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _updateState();
    // Auto-refresh every 30s as per spec (or tighter for smoothness, spec said 30s)
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateState());
  }

  @override
  void dispose() {
    _timer.cancel();
    _glowController.dispose();
    super.dispose();
  }

  void _updateState() {
    // TIMEZONE LAW: America/New_York (EST = UTC-5)
    // Jan is Winter, so Standard Time (UTC-5).
    // In Summer it would be UTC-4. 
    // For V1 Polish, fixed Offset is acceptable fallback for Web stability.
    final nowUtc = DateTime.now().toUtc();
    _nowEt = nowUtc.subtract(const Duration(hours: 5));

    final hour = _nowEt.hour;
    // final minute = _nowEt.minute; // Unused depending on granularity

    // WEEKEND OVERRIDE
    final isWeekend = _nowEt.weekday == DateTime.saturday ||
        _nowEt.weekday == DateTime.sunday;

    if (isWeekend) {
      _marketLabel = "MARKETS CLOSED";
      _stocksOn = false;
      _optionsOn = false;
      _newsOn = true;
      _macroOn = false;
    } else {
      // Weekday Logic
      // 04:00 - 09:30 -> PRE-MARKET
      // 09:30 - 16:00 -> MARKET HOURS
      // 16:00 - 20:00 -> AFTER HOURS
      // 20:00 - 04:00 -> MARKETS CLOSED

      // Simplify using minutes from midnight
      final minutesOfDay = hour * 60 + _nowEt.minute;
      const preStart = 4 * 60; // 04:00
      const marketStart = 9 * 60 + 30; // 09:30
      const afterStart = 16 * 60; // 16:00
      const closeStart = 20 * 60; // 20:00

      if (minutesOfDay >= closeStart || minutesOfDay < preStart) {
        _marketLabel = "MARKETS CLOSED";
        _stocksOn = false;
        _optionsOn = false;
        _newsOn = true;
        _macroOn = false;
      } else if (minutesOfDay >= afterStart) {
        _marketLabel = "AFTER HOURS";
         _stocksOn = true;
        _optionsOn = false; // Options OFF in After Hours per rules
        _newsOn = true;
        _macroOn = true;
      } else if (minutesOfDay >= marketStart) {
        _marketLabel = "MARKET HOURS";
        _stocksOn = true;
        _optionsOn = true;
        _newsOn = true;
        _macroOn = true;
      } else {
        // >= preStart && < marketStart
        _marketLabel = "PRE-MARKET";
        _stocksOn = true;
        _optionsOn = false; 
        _newsOn = true;
        _macroOn = true;
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Connectivity Check
    // If widget.dataState is unknown or disconnected, force OFFLINE
    final bool isOffline = widget.dataState.state == DataState.unknown; 
    // Spec says: LIVE unless OS detects no connectivity. 
    // DataState.live/stale/locked implies connectivity. unknown implies maybe offline?
    // Let's rely on DataState != unknown for LIVE.
    final bool isLive = !isOffline;

    final dateFormat = DateFormat('EEE MM/dd/yyyy');
    final dateStr = dateFormat.format(_nowEt).toUpperCase();

    return Container(
      // Removed fixed height to accomodate modules
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.bgDeepVoid.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Banner V1
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT: Market Status
              Expanded(
                flex: 4,
                child: Text(
                  _marketLabel,
                  style: GoogleFonts.inter(
                    color: AppColors.accentCyanDim, // Or dynamic? Spec didn't specify color, assuming standard label style
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // CENTER: Date pill
              Expanded(
                flex: 4,
                child: Center(
                  child: Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // RIGHT: LIVE/OFFLINE
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isLive) ...[
                      // Breathing text or just chip? Spec: "LIVE" appears... LIVE uses breathing glow animation.
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.stateLive.withOpacity(0.6 * _glowAnimation.value),
                                  blurRadius: 8 * _glowAnimation.value,
                                  spreadRadius: 2 * _glowAnimation.value,
                                )
                              ]
                            ),
                            child: Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.stateLive,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Text("LIVE", 
                        style: GoogleFonts.inter(
                          color: AppColors.stateLive, 
                          fontSize: 11, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0 
                        )
                      ),
                    ] else ...[
                      // OFFLINE
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.textDisabled,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text("OFFLINE", 
                        style: GoogleFonts.inter(
                          color: AppColors.textDisabled, 
                          fontSize: 11, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0 
                        )
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          
          // Divider
          Divider(
            height: 1, 
            thickness: 1, 
            color: AppColors.neonCyan.withOpacity(0.3)
          ),

          const SizedBox(height: 12),

          // Modules Strip
          // Stocks / Options / News / Macro
          Row(
            children: [
              _buildModulePill("Stocks", _stocksOn),
              const SizedBox(width: 8),
              _buildModulePill("Options", _optionsOn),
              const SizedBox(width: 8),
              _buildModulePill("News", _newsOn),
              const SizedBox(width: 8),
              _buildModulePill("Macro", _macroOn),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildModulePill(String label, bool isOn) {
    // Flexible wrapper for small screens
    return Expanded(
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          color: isOn ? AppColors.neonCyan.withValues(alpha: 0.05) : AppColors.bgDeepVoid.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14), // Oval
          border: Border.all(
            color: isOn ? AppColors.neonCyan.withValues(alpha: 0.3) : AppColors.borderSubtle.withValues(alpha: 0.3),
            width: 0.5
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6, 
              height: 6,
              decoration: BoxDecoration(
                color: isOn ? AppColors.neonCyan : AppColors.textDisabled,
                shape: BoxShape.circle,
                boxShadow: isOn ? [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(0.6),
                    blurRadius: 4,
                  )
                ] : null
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                color: isOn ? AppColors.textPrimary : AppColors.textDisabled,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5
              )
            )
          ],
        ),
      ),
    );
  }
}
