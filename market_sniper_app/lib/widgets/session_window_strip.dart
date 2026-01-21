import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../logic/data_state_resolver.dart';
import '../utils/time_utils.dart';
import '../models/system_health_snapshot.dart'; // D45.18
import 'provider_status_indicator.dart'; // D45.18

class SessionWindowStrip extends StatefulWidget {
  final ResolvedDataState dataState;
  final SystemHealthSnapshot? healthSnapshot; // D45.18

  const SessionWindowStrip({
    super.key,
    required this.dataState,
    this.healthSnapshot, // Optional for backward/layout safety
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
    // Formatting: Institutional (hh:mm a ET)
    final dateFormat = DateFormat('EEE MM/dd/yyyy'); 
    final timeFormat = DateFormat('hh:mm a'); // 12:26 PM
    
    final dateStr = dateFormat.format(_currentTimeEt).toUpperCase();
    final timeStr = timeFormat.format(_currentTimeEt);

    // D45.01 Copy Hygiene
    String sessionLabel;
    switch (_currentSession) {
      case SessionState.pre: sessionLabel = "PREMARKET"; break;
      case SessionState.market: sessionLabel = "MARKET HOURS"; break;
      case SessionState.after: sessionLabel = "AFTER HOURS"; break;
      case SessionState.closed: sessionLabel = "MARKET CLOSED"; break;
    }
    
    // Status Chip Logic
    Color statusColor = AppColors.textDisabled; // Default offline
    String statusLabel = "OFFLINE"; // Default offline

    switch (widget.dataState.state) {
       case DataState.live:
          statusColor = AppColors.stateLive;
          statusLabel = "LIVE";
          break;
       case DataState.stale:
          statusColor = AppColors.stateStale;
          statusLabel = "DATA DELAYED";
          break;
       case DataState.locked:
          statusColor = AppColors.stateLocked;
          statusLabel = "LOCKED";
          break;
       case DataState.unknown:
       default:
          statusColor = AppColors.textDisabled;
          statusLabel = "OFFLINE";
          break;
    }

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
          // LEFT: Session Indicator (No Label)
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _sessionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _sessionColor.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text(
                    sessionLabel,
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
                const SizedBox(width: 8), // Tighter GAP

                // D45.18 Provider Status Indicator
                if (widget.healthSnapshot != null)
                   Padding(
                     padding: const EdgeInsets.only(right: 8),
                     child: ProviderStatusIndicator(snapshot: widget.healthSnapshot!),
                   ),

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
