import '../services/api_client.dart';
import '../models/system_health_snapshot.dart';
import '../models/system_health.dart'; // Misfire legacy model
import '../logic/data_state_resolver.dart';

class SystemHealthRepository {
  final ApiClient api;

  SystemHealthRepository({required this.api});

  Future<SystemHealthSnapshot> fetchUnifiedHealth({
    ResolvedDataState? dataState, // To apply override if LOCKED
  }) async {
    // 1. Fetch Primary (health_ext)
    try {
      final extMap = await api.fetchHealthExt();
      if (extMap.isNotEmpty && extMap.containsKey('status')) {
        return _mapFromHealthExt(extMap, dataState);
      }
    } catch (_) {}

    // 2. Fallback (os/health)
    try {
      final osMap = await api.fetchOsHealth();
      if (osMap.isNotEmpty && osMap.containsKey('status')) {
        return _mapFromOsHealth(osMap, dataState);
      }
    } catch (_) {}

    // 3. Fallback (Misfire Legacy)
    try {
      final misfire = await api.fetchSystemHealth();
      if (misfire.status != 'unknown') {
        return _mapFromMisfire(misfire, dataState);
      }
    } catch (_) {}

    return _applyOverride(SystemHealthSnapshot.unknown, dataState);
  }

  SystemHealthSnapshot _mapFromHealthExt(Map<String, dynamic> json, ResolvedDataState? override) {
    final statusStr = (json['status'] as String? ?? 'UNKNOWN').toUpperCase();
    final timestamp = json['timestamp'] as String?;
    // Calculate age if timestamp exists, or use provided age field
    int age = 0; // TODO: Parse timestamp if needed, but for now rely on mapped fields if any
    
    // health_ext usually has 'generated_at' or 'timestamp'
    
    HealthStatus status = _parseStatus(statusStr);
    
    return _applyOverride(SystemHealthSnapshot(
      status: status,
      source: HealthSource.ext,
      ageSeconds: age, // Placeholder unless we parse
      message: statusStr,
      rawTimestamp: timestamp,
    ), override);
  }

  SystemHealthSnapshot _mapFromOsHealth(Map<String, dynamic> json, ResolvedDataState? override) {
    final statusStr = (json['status'] as String? ?? 'UNKNOWN').toUpperCase();
    
    return _applyOverride(SystemHealthSnapshot(
      status: _parseStatus(statusStr),
      source: HealthSource.os,
      ageSeconds: 0,
      message: statusStr,
    ), override);
  }

  SystemHealthSnapshot _mapFromMisfire(SystemHealth misfire, ResolvedDataState? override) {
    return _applyOverride(SystemHealthSnapshot(
      status: _parseStatus(misfire.status),
      source: HealthSource.misfire,
      ageSeconds: misfire.artifactAgeSeconds.round(),
      message: misfire.status,
    ), override);
  }

  SystemHealthSnapshot _applyOverride(SystemHealthSnapshot snapshot, ResolvedDataState? override) {
    if (override != null && override.state == DataState.locked) {
      return SystemHealthSnapshot(
        status: HealthStatus.locked,
        source: snapshot.source,
        ageSeconds: snapshot.ageSeconds,
        message: "LOCKED (${override.reason.name})",
        rawTimestamp: snapshot.rawTimestamp,
      );
    }
    return snapshot;
  }

  HealthStatus _parseStatus(String s) {
    final up = s.toUpperCase();
    if (up == 'NOMINAL' || up == 'OK' || up == 'LIVE') return HealthStatus.nominal;
    if (up.contains('DEGRADED')) return HealthStatus.degraded;
    if (up.contains('MISFIRE')) return HealthStatus.misfire;
    if (up.contains('LOCKED') || up.contains('FRACTURED') || up.contains('SAFE')) return HealthStatus.locked;
    return HealthStatus.unknown;
  }
}
