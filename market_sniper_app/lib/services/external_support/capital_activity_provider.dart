
enum CapitalActivityStatus {
  unplugged,
  mock,
  live,
}

class CapitalActivityResult {
  final CapitalActivityStatus status;
  final DateTime asOfUtc;
  final String summary;
  final String bias; // "Bullish", "Bearish", "Mixed", "Neutral"
  final String sourceName; // e.g. "Unusual Whales", "Simulation"
  final bool isError;

  const CapitalActivityResult({
    required this.status,
    required this.asOfUtc,
    required this.summary,
    required this.bias,
    required this.sourceName,
    this.isError = false,
  });

  // Factory for Unplugged State (Default)
  factory CapitalActivityResult.unplugged() {
    return CapitalActivityResult(
      status: CapitalActivityStatus.unplugged,
      asOfUtc: DateTime.now().toUtc(),
      summary: "External source unplugged",
      bias: "Neutral",
      sourceName: "System",
    );
  }

  // Factory for Mock State
  factory CapitalActivityResult.mock({
    required String summary,
    required String bias,
  }) {
    return CapitalActivityResult(
      status: CapitalActivityStatus.mock,
      asOfUtc: DateTime.now().toUtc(),
      summary: summary,
      bias: bias,
      sourceName: "Simulation (MOCK)",
    );
  }
}

abstract class CapitalActivityProvider {
  Future<CapitalActivityResult> fetchActivity(String symbol);
}
