import 'package:flutter/foundation.dart';
import 'market_time_helper.dart';
import 'plus_unlock_store.dart';
import '../config/app_config.dart';

class PlusUnlockEngine {
  static const int _kTarget = 5;

  /// Main entry point called on App Start
  static Future<void> checkAndIncrement() async {
    if (AppConfig.isFounderBuild) return; // Founders bypass, no need to track?
    // Actually, prompt says "Plus unlocks... Elite unlocks Day 1".
    // If user is Plus, we track. If Elite user?
    // If Elite, they have Day 1 access.
    // If they downgrade to Plus? They might need progress.
    // Safest: Track for everyone? Or just track if current tier is Plus?
    // Let's track for everyone to build history (growth).
    // And it's harmless.

    try {
      final nowEt = MarketTimeHelper.getNowEt();

      // 1. Must be Market Hours (09:30 - 16:00 ET)
      if (!MarketTimeHelper.isMarketHours(nowEt)) {
        return;
      }

      // 2. Must be a new day
      final todayId = MarketTimeHelper.getMarketDayId(nowEt);
      final lastDate = await PlusUnlockStore.getLastDate();

      if (lastDate == todayId) {
        // Already counted today
        return;
      }

      // 3. Increment
      await PlusUnlockStore.increment(todayId);
      if (kDebugMode) {
        print("[PLUS_UNLOCK] Incremented for $todayId");
      }
    } catch (e) {
      if (kDebugMode) print("[PLUS_UNLOCK] Error: $e");
    }
  }

  static Future<bool> isUnlocked() async {
    return await PlusUnlockStore.isUnlocked();
  }

  static Future<String> getProgressString() async {
    final count = await PlusUnlockStore.getCount();
    if (count >= _kTarget) return "UNLOCKED";
    return "$count/$_kTarget Market Opens";
  }
}
