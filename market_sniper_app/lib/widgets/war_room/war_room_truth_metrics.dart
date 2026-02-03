import '../../models/war_room_snapshot.dart';
import '../../models/system_health_snapshot.dart';

class TruthMetricResult {
  final bool fetchOk;
  final int? httpStatus;
  final int? ageSeconds;
  final int realCount;
  final int totalCount;
  final double coveragePct; // Added for D53.6Y
  final List<String> topNaTiles;

  TruthMetricResult({
    required this.fetchOk,
    this.httpStatus,
    this.ageSeconds,
    required this.realCount,
    required this.totalCount,
    required this.topNaTiles,
    required this.coveragePct,
  });
}

TruthMetricResult computeTruthMetrics(WarRoomSnapshot snapshot,
    {required DateTime nowUtc}) {
  // 1. FETCH STATUS
  // Check explicit status code if available (D53.6A)
  int? status = snapshot.warRoomHttpStatus;
  bool fetchOk = status != null && status >= 200 && status < 300;

  // 2. AGE
  int? ageSeconds;
  if (snapshot.universe.timestampUtc != "N/A") {
    try {
      final ts = DateTime.parse(snapshot.universe.timestampUtc);
      ageSeconds = nowUtc.difference(ts).inSeconds;
      if (ageSeconds < 0) ageSeconds = 0; // Clock skew safety
      // Safety cap for display logic
    } catch (e) {
      ageSeconds = null; // Parse error
    }
  }

  // 3. REAL vs TOTAL vs N/A
  // Define the canonical list of tiles we expect in War Room V2
  // This must match the UI structure (Global + Honeycomb + Strip + Console)
  final expectedTiles = <String, bool>{
    'OS_HEALTH': snapshot.osHealth.status != HealthStatus.unknown,
    'AUTOPILOT': snapshot.autopilot.isAvailable,
    'MISFIRE': snapshot.misfire.isAvailable,
    'HOUSEKEEPER': snapshot.housekeeper.isAvailable,
    'IRON_OS': snapshot.iron.isAvailable,
    'UNIVERSE': snapshot.universe.isAvailable,
    'IRON_TIMELINE': snapshot.ironTimeline.isAvailable,
    'IRON_HISTORY': snapshot.ironHistory.isAvailable,
    'LKG': snapshot.lkg.isAvailable,
    'DECISION_PATH': snapshot.decisionPath.isAvailable,
    'DRIFT': snapshot.drift.isAvailable,
    'REPLAY_INTEGRITY': snapshot.replay.isAvailable,
    'LOCK_REASON': snapshot.lockReason.isAvailable,
    'COVERAGE': snapshot.coverage.isAvailable,
    'FINDINGS': snapshot.findings != FindingsSnapshot.unknown,
    'TIER1': snapshot.autofixTier1.isAvailable,
    'ROOT_CAUSE': snapshot.misfireRootCause.isAvailable,
    'CONFIDENCE': snapshot.selfHealConfidence.isAvailable,
    'WHAT_CHANGED': snapshot.selfHealWhatChanged.isAvailable,
    'COOLDOWN': snapshot.cooldownTransparency.isAvailable,
    'RED_BUTTON': snapshot.redButton.available, // Special case: availability
    'TIER2': snapshot.misfireTier2.isAvailable,
    'OPTIONS': snapshot.options.isAvailable,
    'MACRO': snapshot.macro.isAvailable,
    'EVIDENCE': snapshot.evidence.isAvailable,
  };

  int realCount = 0;
  List<String> naList = [];

  expectedTiles.forEach((key, isReal) {
    if (isReal) {
      realCount++;
    } else {
      naList.add(key);
    }
  });

  // Coverage Percentage
  double coveragePct = expectedTiles.isEmpty
      ? 0.0
      : (realCount / expectedTiles.length) * 100.0;

  // Take top 5 N/A for display (D53.6Y)
  final topNa = naList.take(5).toList();

  return TruthMetricResult(
    fetchOk: fetchOk,
    httpStatus: status,
    ageSeconds: ageSeconds,
    realCount: realCount,
    totalCount: expectedTiles.length,
    topNaTiles: topNa,
    coveragePct: coveragePct,
  );
}
