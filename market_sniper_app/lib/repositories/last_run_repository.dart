import '../services/api_client.dart';
import '../models/last_run_snapshot.dart'; // D37.05 Model

class LastRunRepository {
  final ApiClient api;

  LastRunRepository({required this.api});

  Future<LastRunSnapshot> fetchLastRun() async {
    try {
      // Use health_ext as canonical source for RunManifest
      final map = await api.fetchHealthExt();

      final data = map['data'];
      if (data != null && map['status'] == 'VALID') {
        return _mapFromManifest(data);
      } else if (data != null && map.containsKey('data')) {
        // Even if fallback, try to parse data if present
        return _mapFromManifest(data);
      }
    } catch (_) {
      // Squelch for resilience
    }
    return LastRunSnapshot.unknown;
  }

  LastRunSnapshot _mapFromManifest(Map<String, dynamic> json) {
    final modeStr = (json['mode'] as String? ?? 'UNKNOWN').toUpperCase();
    final statusStr = (json['status'] as String? ?? 'UNKNOWN').toUpperCase();
    final runId = json['run_id'] as String? ?? 'UNKNOWN';
    final timestampStr = json['timestamp'] as String?; // "2026-01-14T03:00:00Z"

    // Parse Type
    LastRunType type = LastRunType.unknown;
    if (modeStr == 'FULL') {
      type = LastRunType.full;
    }
    if (modeStr == 'LIGHT') {
      type = LastRunType.light;
    }

    // Parse Result
    LastRunResult result = LastRunResult.unknown;
    if (statusStr == 'SUCCESS' || statusStr == 'OK') {
      result = LastRunResult.ok;
    } else if (statusStr == 'PARTIAL') {
      result = LastRunResult.partial;
    } else if (statusStr == 'MISFIRE') {
      result = LastRunResult.misfire;
    } else if (statusStr == 'FAILED' || statusStr == 'FAILURE') {
      result = LastRunResult.failed;
    }

    // Calculate Age
    int age = -1;
    if (timestampStr != null) {
      try {
        final nowUtc = DateTime.now().toUtc();
        final runTimeUtc = DateTime.parse(timestampStr).toUtc();
        age = nowUtc.difference(runTimeUtc).inSeconds;
      } catch (_) {}
    }

    return LastRunSnapshot(
        type: type,
        result: result,
        ageSeconds: age,
        runId: runId,
        timestamp: timestampStr);
  }
}
