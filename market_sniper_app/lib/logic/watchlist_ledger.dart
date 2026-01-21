import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../repositories/watchlist_log_repository.dart';

/// Appends actions to local JSONL ledger AND sends to Backend.
/// Path: [ApplicationSupportDirectory]/watchlist_actions_ledger.jsonl
class WatchlistLedger {
  static final WatchlistLedger _instance = WatchlistLedger._internal();
  factory WatchlistLedger() => _instance;
  WatchlistLedger._internal();
  
  final _repo = WatchlistLogRepository();

  Future<void> logAction({
    required String action,
    required String ticker,
    required String resolvedState,
    required String result, // Maps to 'outcome' in backend roughly, or result
    String? lockReason,
    String sourceScreen = "Watchlist",
  }) async {
    // 1. Local Write
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/watchlist_actions_ledger.jsonl');
      
      final entry = {
        "timestamp_utc": DateTime.now().toUtc().toIso8601String(),
        "action": action,
        "ticker": ticker,
        "resolved_state": resolvedState,
        "result": result,
        if (lockReason != null) "lock_reason": lockReason,
        "source_screen": sourceScreen,
      };

      await file.writeAsString(jsonEncode(entry) + '\n', mode: FileMode.append);
    } catch (e) {
      // Fail silent
    }
    
    // 2. Backend Write (Fire & Forget)
    // Map 'result' to backend 'outcome'
    // result="BLOCKED" -> outcome="BLOCKED"
    // result="OPENED_RESULT" -> outcome="SUCCESS"
    // else -> "NO_OP"
    
    String backendOutcome = "SUCCESS";
    if (result == "BLOCKED") backendOutcome = "BLOCKED";
    else if (result == "NO_OP") backendOutcome = "NO_OP";
    
    // Backend action mapping if needed, or pass through
    // Backend expects: ADD, REMOVE, ANALYZE_TAP, BLOCKED_LOCKED, BLOCKED_STALE, OPENED_ON_DEMAND, RESULT_RENDERED
    // We infer from action + result
    
    String backendAction = action;
    if (action == "ANALYZE_NOW") {
        if (result == "BLOCKED") {
           // Try to guess LOCKED vs STALE from resolvedState
           if (resolvedState == "LOCKED") backendAction = "BLOCKED_LOCKED";
           else if (resolvedState == "STALE") backendAction = "BLOCKED_STALE";
           else backendAction = "BLOCKED_LOCKED"; // Fallback
        } else {
           backendAction = "OPENED_ON_DEMAND";
        }
    }

    try {
        await _repo.logAction(
            action: backendAction, 
            ticker: ticker, 
            outcome: backendOutcome, 
            resolvedState: resolvedState,
            lockReason: lockReason,
            sourceScreen: sourceScreen
        );
    } catch (_) {
        // Swallow backend errors
    }
  }
}
