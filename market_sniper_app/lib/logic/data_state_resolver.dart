import '../models/dashboard_payload.dart';
import '../models/system_health.dart';

enum DataState {
  live,
  stale,
  locked,
  unknown,
}

enum StateReason {
  fresh,
  staleAge,
  misfire,
  watchdogLock,
  failsafeLock,
  immuneLock,
  unknown,
}

class ResolvedDataState {
  final DataState state;
  final StateReason reason;
  final String debugMessage;
  final int ageSeconds;

  const ResolvedDataState({
    required this.state,
    required this.reason,
    required this.debugMessage,
    required this.ageSeconds,
  });

  static const ResolvedDataState unknown = ResolvedDataState(
    state: DataState.unknown,
    reason: StateReason.unknown,
    debugMessage: "No Data",
    ageSeconds: -1,
  );
}

class DataStateResolver {
  static const int staleThresholdSeconds = 300; // 5 minutes canonical

  static ResolvedDataState resolve({
    required DashboardPayload? dashboard,
    required SystemHealth? health,
  }) {
    if (dashboard == null) {
      return ResolvedDataState.unknown;
    }

    // 1. LOCKED (Highest Precedence)
    // Check Health Signals
    if (health != null) {
      final statusUpper = health.status.toUpperCase();
      if (statusUpper.contains('MISFIRE')) {
        return _build(DataState.locked, StateReason.misfire, "Health: MISFIRE", dashboard);
      }
      if (statusUpper.contains('LOCKED') || statusUpper.contains('FRACTURED')) {
        return _build(DataState.locked, StateReason.immuneLock, "Health: $statusUpper", dashboard);
      }
    }

    // Check SSOT Signals
    final sysStatus = dashboard.systemStatus.toUpperCase();
    if (sysStatus.contains('LOCKED')) {
      return _build(DataState.locked, StateReason.watchdogLock, "SSOT: LOCKED", dashboard);
    }
    if (sysStatus.contains('SAFE_MODE')) {
      return _build(DataState.locked, StateReason.failsafeLock, "SSOT: SAFE_MODE", dashboard);
    }

    // 2. STALE
    final age = dashboard.ageSeconds;
    if (age > staleThresholdSeconds) {
      return _build(DataState.stale, StateReason.staleAge, "Age > ${staleThresholdSeconds}s", dashboard);
    }

    // 3. LIVE
    return _build(DataState.live, StateReason.fresh, "Fresh (<${staleThresholdSeconds}s)", dashboard);
  }

  static ResolvedDataState _build(
    DataState state,
    StateReason reason,
    String msg,
    DashboardPayload d,
  ) {
    return ResolvedDataState(
      state: state,
      reason: reason,
      debugMessage: msg,
      ageSeconds: d.ageSeconds,
    );
  }
}
