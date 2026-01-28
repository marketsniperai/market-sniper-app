
class RegimeSentinelModel {
  final String indexSymbol; // SPY, QQQ
  final DateTime? currentFrame; // UTC
  final List<dynamic>? pastFrames; // Placeholder for now
  final Map<String, dynamic>? futureScenarios; // { "base": ..., "stress": ... }
  final String? evidenceSummary;
  final String? macroSummary;
  final List<String>? enginesUsed;

  const RegimeSentinelModel({
    required this.indexSymbol,
    this.currentFrame,
    this.pastFrames,
    this.futureScenarios,
    this.evidenceSummary,
    this.macroSummary,
    this.enginesUsed,
  });

  // Empty/Skeleton Factory
  factory RegimeSentinelModel.skeleton(String symbol) {
    return RegimeSentinelModel(indexSymbol: symbol);
  }
}
