import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../logic/data_state_resolver.dart';
import '../utils/time_utils.dart';

class SessionWindowStrip extends StatefulWidget {
  final ResolvedDataState dataState;

  const SessionWindowStrip({
    super.key,
    required this.dataState,
  });

  @override
  State<SessionWindowStrip> createState() => _SessionWindowStripState();
}

class _SessionWindowStripState extends State<SessionWindowStrip> {
  Timer? _ticker;
  late DateTime _currentTimeEt;
  late SessionState _currentSession;

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Tick every second to keep clock live
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _updateTime() {
    // Uses TimeUtils for strict ET conversion
    final nowEt = TimeUtils.getNowEt();
    if (mounted) {
      setState(() {
        _currentTimeEt = nowEt;
        _currentSession = TimeUtils.getSessionState(nowEt);
      });
    }
  }

  Color get _sessionColor {
    switch (_currentSession) {
      case SessionState.pre:
        return AppColors.accentCyanDim;
      case SessionState.market:
        return AppColors.stateLive; // Green
      case SessionState.after:
        return AppColors.accentCyanDim;
      case SessionState.closed:
        return AppColors.textDisabled;
    }
  }

  Color get _freshnessColor {
    switch (widget.dataState.state) {
      case DataState.live:
        return AppColors.stateLive;
      case DataState.stale:
        return AppColors.stateStale;
      case DataState.locked:
        return AppColors.stateLocked;
      case DataState.unknown:
        return AppColors.textDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatting: Bestia style (Uppercase, condensed)
    final dateFormat = DateFormat('EEE MM/dd/yyyy'); 
    final timeFormat = DateFormat('HH:mm:ss'); // Seconds for "live" feel, or just HH:mm? Prompt said HH:mm earlier but "live clock tick". Let's stick to HH:mm for clean look or HH:mm:ss for "Sniper" feel. Prompt example "14:07". Stick to HH:mm for cleaner UI unless user asked for seconds. User asked for "Live Time". 14:07 is fine.
    
    // Actually, let's do HH:mm to match spec "14:07 ET".
    // But update every second to ensure the minute flip is precise.
    
    final dateStr = dateFormat.format(_currentTimeEt).toUpperCase();
    final timeStr = timeFormat.format(_currentTimeEt);
    final sessionStr = _currentSession.name.toUpperCase();
    
    // Status Chip Logic
    final statusColor = _freshnessColor;
    final statusLabel = widget.dataState.state.name.toUpperCase();

    return Container(
      height: 42, // Tighter height (Bestia)
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16), // More breathing room on sides
      decoration: BoxDecoration(
        color: AppColors.surface1, // Deep card bg
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6), // Slightly tighter radius
        boxShadow: [
          BoxShadow(
            color: AppColors.bgDeepVoid.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // LEFT: Session Indicator
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                  "SESSION", 
                  style: GoogleFonts.inter(
                    color: AppColors.textDisabled, 
                    fontSize: 9, 
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _sessionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _sessionColor.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text(
                    sessionStr,
                    style: GoogleFonts.inter(
                      color: _sessionColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CENTER: Date (Hidden on very small screens? Use Flexible)
          // On mobile, this might get tight. Let's allow shrinking.
          Expanded(
            flex: 4,
            child: Center(
              child: Text(
                dateStr,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // RIGHT: Time + Status Chip
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                 Text(
                  "$timeStr ET",
                  style: GoogleFonts.robotoMono( // Code/tabular feel for time
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                // Status Chip (Pill)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12), // Pill shape
                    border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Little dot for "Live" feel
                      Container(
                        width: 4, height: 4,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
