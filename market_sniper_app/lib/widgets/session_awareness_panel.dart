import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../logic/market_time_helper.dart';

class SessionAwarenessPanel extends StatefulWidget {
  const SessionAwarenessPanel({super.key});

  @override
  State<SessionAwarenessPanel> createState() => _SessionAwarenessPanelState();
}

class _SessionAwarenessPanelState extends State<SessionAwarenessPanel>
    with WidgetsBindingObserver {
  late Timer _timer;
  _SessionState _currentState = _SessionState.closed;
  Duration _timeUntilNext = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateState();
    // 1-minute resolution timer
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateState();
    }
  }

  void _updateState() {
    final nowEt = MarketTimeHelper.getNowEt();
    final result = _calculateSession(nowEt);
    if (mounted) {
      setState(() {
        _currentState = result.state;
        _timeUntilNext = result.timeUntilCallback(nowEt);
      });
    }
  }

  _SessionCalculation _calculateSession(DateTime nowEt) {
    // Check Weekend
    if (nowEt.weekday == DateTime.saturday ||
        nowEt.weekday == DateTime.sunday) {
      // Weekend -> Next is Monday 04:00
      // Calculate days until Monday
      int daysUntilMon = (8 - nowEt.weekday) % 7;
      if (daysUntilMon == 0) {
        daysUntilMon = 7; // Should be handled but explicit safety
      }

      final nextMon = DateTime(nowEt.year, nowEt.month, nowEt.day)
          .add(Duration(days: daysUntilMon));
      final nextSession = nextMon.add(const Duration(hours: 4)); // 04:00

      return _SessionCalculation(
        state: _SessionState.closed,
        timeUntilCallback: (now) => nextSession.difference(now),
      );
    }

    // Weekday Logic
    // 00:00 - 04:00: CLOSED (Wait for 04:00)
    // 04:00 - 09:30: PREMARKET (Wait for 09:30)
    // 09:30 - 16:00: MARKET (Wait for 16:00)
    // 16:00 - 20:00: AFTER (Wait for 20:00)
    // 20:00 - 24:00: CLOSED (Wait for Tomorrow 04:00)

    final time = nowEt.hour + (nowEt.minute / 60.0);

    if (time < 4.0) {
      // Before 4AM -> CLOSED, Next 4AM Today
      final target = DateTime(nowEt.year, nowEt.month, nowEt.day, 4, 0);
      return _SessionCalculation(
          state: _SessionState.closed,
          timeUntilCallback: (now) => target.difference(now));
    } else if (time < 9.5) {
      // Pre-Market -> Next 9:30
      final target = DateTime(nowEt.year, nowEt.month, nowEt.day, 9, 30);
      return _SessionCalculation(
          state: _SessionState.premarket,
          timeUntilCallback: (now) => target.difference(now));
    } else if (time < 16.0) {
      // Market -> Next 16:00
      final target = DateTime(nowEt.year, nowEt.month, nowEt.day, 16, 0);
      return _SessionCalculation(
          state: _SessionState.market,
          timeUntilCallback: (now) => target.difference(now));
    } else if (time < 20.0) {
      // After -> Next 20:00
      final target = DateTime(nowEt.year, nowEt.month, nowEt.day, 20, 0);
      return _SessionCalculation(
          state: _SessionState.afterhours,
          timeUntilCallback: (now) => target.difference(now));
    } else {
      // Post 20:00 -> CLOSED, Next Tomorrow 04:00
      // Check if tomorrow is weekend?
      final tomorrow = nowEt.add(const Duration(days: 1));
      if (tomorrow.weekday == DateTime.saturday) {
        // Tomorrow sat -> Next Mon 04:00
        final nextMon = tomorrow.add(const Duration(days: 2));
        final target = DateTime(nextMon.year, nextMon.month, nextMon.day, 4, 0);
        return _SessionCalculation(
            state: _SessionState.closed,
            timeUntilCallback: (now) => target.difference(now));
      } else {
        // Weekday tomorrow
        final target =
            DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 4, 0);
        return _SessionCalculation(
            state: _SessionState.closed,
            timeUntilCallback: (now) => target.difference(now));
      }
    }
  }

  Color _getColor() {
    switch (_currentState) {
      case _SessionState.premarket:
        return AppColors.neonCyan;
      case _SessionState.market:
        return AppColors.stateLive; // Green
      case _SessionState.afterhours:
        return AppColors.stateStale; // Amber/Gold (stateStale is Yellow/Gold)
      case _SessionState.closed:
        return AppColors.textDisabled; // Grey
    }
  }

  String _getLabel() {
    switch (_currentState) {
      case _SessionState.premarket:
        return "PRE-MARKET";
      case _SessionState.market:
        return "MARKET HOURS";
      case _SessionState.afterhours:
        return "AFTER HOURS";
      case _SessionState.closed:
        return "MARKET CLOSED";
    }
  }

  String _getNextLabel() {
    switch (_currentState) {
      case _SessionState.premarket:
        return "Market Open";
      case _SessionState.market:
        return "Close";
      case _SessionState.afterhours:
        return "Closed"; // or "Session End"
      case _SessionState.closed:
        return "Pre-Market";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_timeUntilNext.isNegative) _updateState(); // Sanity check

    final hours = _timeUntilNext.inHours;
    final minutes = _timeUntilNext.inMinutes.remainder(60);
    final timeStr =
        "${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m";
    final color = _getColor();

    return Container(
      width: double.infinity,
      height: 28,
      color: AppColors.surface1, // Base background
      child: Stack(
        children: [
          // Passive fill indicator? Maybe too much "active".
          // Spec says "Compact horizontal strip... Color Canon".
          // Maybe just border-bottom or colored text?
          // "PREMARKET -> Cyan". Let's use a colored bar on left or full text color.
          // Elegant: Full row, text color matches state.

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Session Label
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(_getLabel(),
                        style: AppTypography.label(context).copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ],
                ),

                // Right: Next Countdown
                Text("Next: ${_getNextLabel()} in $timeStr",
                    style: AppTypography.label(context).copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontFamily: 'RobotoMono')),
              ],
            ),
          ),

          // Bottom hairline
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(height: 1, color: AppColors.borderSubtle)),
        ],
      ),
    );
  }
}

enum _SessionState { premarket, market, afterhours, closed }

class _SessionCalculation {
  final _SessionState state;
  final Duration Function(DateTime) timeUntilCallback;
  _SessionCalculation({required this.state, required this.timeUntilCallback});
}
