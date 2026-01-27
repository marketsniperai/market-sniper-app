import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'on_demand_history_store.dart';

/// Helper to resolve the "Last Analyzed" timestamp for a ticker.
/// Priority:
/// 1. OnDemandHistoryStore (Frontend Local, immediate UX)
/// 2. Watchlist Ledger (Fallback, persisted logs)
class WatchlistLastAnalyzedResolver {
  final OnDemandHistoryStore _historyStore = OnDemandHistoryStore();

  /// Resolves the last analyzed timestamp for a given ticker.
  Future<DateTime?> resolve(String ticker) async {
    final cleanTicker = ticker.toUpperCase().trim();

    // 1. Check History Store (In-Memory / Fast Local)
    // HistoryStore keeps last 5. If it's there, it's likely the most recent.
    final historyItems = _historyStore.getRecent();
    for (var item in historyItems) {
      if (item.ticker == cleanTicker) {
        return DateTime.tryParse(item.timestampUtc);
      }
    }

    // 2. Fallback: Parse Ledger (Expensive, but comprehensive)
    // We scan standard_envelope.dartthe ledger file backwards if possible, or naive read.
    // For MVP, we do a simple read.
    // Optimization: Since we might check many tickers, ideally we'd cache this,
    // but D44.10 specifies "No new writes, just read".
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/watchlist_actions_ledger.jsonl');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        // Search backwards
        for (var i = lines.length - 1; i >= 0; i--) {
          final line = lines[i];
          if (line.isEmpty) continue;
          try {
            final entry = jsonDecode(line);
            // Check action type. We care about successful analysis.
            // Actions: "ANALYZE_NOW" -> result: "OPENED_RESULT" or "BLOCKED" (if we want to show attempted?)
            // Prompt says "Last analyzed" -> implies success or at least attempt.
            // Let's count "OPENED_RESULT" as a true analysis. "BLOCKED" is an attempt.
            // Context Engine usually requires successful run to be "Analyzed".
            if (entry['ticker'] == cleanTicker &&
                (entry['action'] == 'ANALYZE_NOW' &&
                        entry['result'] == 'OPENED_RESULT' ||
                    entry['action'] == 'OPENED_ON_DEMAND')) {
              return DateTime.tryParse(entry['timestamp_utc']);
            }
          } catch (_) {}
        }
      }
    } catch (_) {
      // Ignore FS errors
    }

    return null;
  }
}
