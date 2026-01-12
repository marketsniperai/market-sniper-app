class ContextPayload {
  final String summary;
  final double globalRiskScore;
  final String? generatedAt;
  final Map<String, dynamic> dailyStatPack;

  ContextPayload({
    required this.summary,
    required this.globalRiskScore,
    this.generatedAt,
    required this.dailyStatPack,
  });

  factory ContextPayload.fromJson(Map<String, dynamic> json) {
    return ContextPayload(
      summary: json['summary'] ?? '',
      globalRiskScore: (json['global_risk_score'] ?? 0.0).toDouble(),
      generatedAt: json['generated_at'],
      dailyStatPack: json['daily_stat_pack'] ?? {},
    );
  }
}
