enum LastRunResult {
  ok,
  partial,
  misfire,
  failed,
  unknown
}

enum LastRunType {
  full,
  light,
  unknown
}

class LastRunSnapshot {
  final LastRunType type;
  final LastRunResult result;
  final int ageSeconds;
  final String runId;
  final String? timestamp;

  const LastRunSnapshot({
    required this.type,
    required this.result,
    required this.ageSeconds,
    required this.runId,
    this.timestamp,
  });

  static const LastRunSnapshot unknown = LastRunSnapshot(
    type: LastRunType.unknown,
    result: LastRunResult.unknown,
    ageSeconds: -1,
    runId: "UNKNOWN",
  );
}
