enum HealthStatus {
  nominal,
  degraded,
  misfire,
  locked,
  unknown,
}

enum HealthSource {
  ext,
  os,
  misfire,
  unknown,
}

class SystemHealthSnapshot {
  final HealthStatus status;
  final HealthSource source;
  final int ageSeconds;
  final String message;
  final String? rawTimestamp;
  final Map<String, String> providers; // D45.18 Provider Status

  const SystemHealthSnapshot({
    required this.status,
    required this.source,
    required this.ageSeconds,
    required this.message,
    this.rawTimestamp,
    this.providers = const {}, 
  });

  static const SystemHealthSnapshot unknown = SystemHealthSnapshot(
    status: HealthStatus.unknown,
    source: HealthSource.unknown,
    ageSeconds: -1,
    message: "Initializing...",
    providers: {},
  );
}
