import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import 'market_time_helper.dart';
import 'trial_state_store.dart';

class TrialEngine {
  static final TrialStateStore _store = TrialStateStore();

  // In-memory cache for speed
  static int _cachedCount = 0;
  static String _cachedStatus = 'ACTIVE';

  static int get currentCount => _cachedCount;
  static bool get isComplete => _cachedStatus == 'COMPLETE';

  static Future<void> checkAndIncrement() async {
    // 1. Load state
    final state = await _store.loadState();
    _cachedCount = state['count'];
    _cachedStatus = state['status'];

    // Ensure install timestamp
    if (state['install_u'] == null) {
      await _store
          .setInstallTimeIfNeeded(DateTime.now().toUtc().toIso8601String());
    }

    // Founder bypass
    if (AppConfig.isFounderBuild) {
      _cachedStatus = 'COMPLETE'; // Treat as unlocked/complete effectively
      return;
    }

    if (_cachedStatus == 'COMPLETE') return;

    // 2. Check conditions
    final nowEt = MarketTimeHelper.getNowEt();

    // Condition A: Market Hours
    if (!MarketTimeHelper.isMarketHours(nowEt)) {
      debugPrint("TRIAL: Outside market hours. No count.");
      return;
    }

    // Condition B: New Market Day
    final todayId = MarketTimeHelper.getMarketDayId(nowEt);
    final lastDayId = state['last_day'];

    if (todayId != lastDayId) {
      // INCREMENT
      int newCount = _cachedCount + 1;
      // Boundary check
      if (newCount > 3) newCount = 3;

      debugPrint("TRIAL: Incrementing count to $newCount (Day $todayId)");
      await _store.updateCount(newCount, todayId);
      _cachedCount = newCount;

      // Completion check
      if (newCount >= 3) {
        debugPrint("TRIAL: Status COMPLETE");
        await _store.setStatusComplete();
        _cachedStatus = 'COMPLETE';
      }
    } else {
      debugPrint("TRIAL: Already counted for day $todayId.");
    }
  }
}
