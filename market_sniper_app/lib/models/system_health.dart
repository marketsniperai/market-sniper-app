class SystemHealth {
  final String status;
  final double artifactAgeSeconds;
  final String reason;
  final String? lastRunId;
  final String? timestampUtc;
  final String recommendedAction;

  SystemHealth({
    required this.status,
    required this.artifactAgeSeconds,
    required this.reason,
    this.lastRunId,
    this.timestampUtc,
    required this.recommendedAction,
  });

  int get artifactAgeMinutes => (artifactAgeSeconds / 60).round();

  factory SystemHealth.fromJson(Map<String, dynamic> json) {
    return SystemHealth(
      status: json['status'] ?? 'UNKNOWN',
      artifactAgeSeconds: (json['artifact_age_seconds'] ?? 0).toDouble(),
      reason: json['reason'] ?? 'UNKNOWN',
      lastRunId: json['last_run_id'],
      timestampUtc: json['timestamp_utc'],
      recommendedAction: json['recommended_action'] ?? 'NONE',
    );
  }

  // Fallback for UI when API is unreachable
  factory SystemHealth.unavailable(String error) {
    return SystemHealth(
      status: 'UNAVAILABLE',
      artifactAgeSeconds: 0,
      reason: error,
      recommendedAction: 'CHECK_CONNECTION',
    );
  }
}
