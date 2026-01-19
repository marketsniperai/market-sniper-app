import '../services/api_client.dart';

class WatchlistLogRepository {
  final ApiClient _api;

  WatchlistLogRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<void> logAction({
    required String action,
    required String ticker,
    required String outcome, // SUCCESS | BLOCKED | NO_OP
    required String resolvedState,
    String? lockReason,
    String sourceScreen = "Watchlist", // metadata
  }) async {
    final event = {
      "timestamp_utc": DateTime.now().toUtc().toIso8601String(),
      "actor": "USER",
      "action": action,
      "ticker": ticker,
      "tier": "FOUNDER", // Hardcoded for now per context
      "outcome": outcome,
      "reason": lockReason,
      "metadata": {
        "source": sourceScreen,
        "resolved_state": resolvedState,
      }
    };

    // Fire and forget
    await _api.postWatchlistLog(event);
  }
}
