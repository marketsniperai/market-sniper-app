
/// Enum for Watchlist Ticker State (D44.09)
enum WatchlistTickerState { live, stale, locked }

/// Helper to resolve the efficient state of a ticker for list rendering.
/// Reuses logic from Analyze Now flow and Context Engine status.
class WatchlistStateResolver {
  WatchlistTickerState _globalState = WatchlistTickerState.live;

  /// Updates the internal global baseline based on System Health status.
  /// [healthStatus] should be "LOCKED", "DEGRADED", "NOMINAL", etc.
  void setGlobalStateFromHealth(String healthStatus) {
    final status = healthStatus.toUpperCase();
    if (status.contains('LOCKED') || status.contains('BLOCKED')) {
      _globalState = WatchlistTickerState.locked;
    } else if (status.contains('DEGRADED') || status.contains('MISFIRE') || status.contains('STALE')) {
      _globalState = WatchlistTickerState.stale;
    } else {
      _globalState = WatchlistTickerState.live;
    }
  }

  /// Resolves the specific state for a ticker.
  /// Currently applies Global State policy. Future tiers can apply overrides here.
  WatchlistTickerState resolve(String ticker) {
    // 1. Global Overrides (Safety Fallback)
    if (_globalState == WatchlistTickerState.locked) return WatchlistTickerState.locked;
    if (_globalState == WatchlistTickerState.stale) return WatchlistTickerState.stale;

    // 2. Default
    return WatchlistTickerState.live;
  }
}
