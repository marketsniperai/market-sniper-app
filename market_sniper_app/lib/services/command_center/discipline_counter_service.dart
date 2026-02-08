import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../models/command_center/command_center_tier.dart';

class CommandCenterAccessState {
  final CommandCenterTier tier;
  final bool isDoorUnlocked;
  final int plusDaysRemaining;
  final String? lastMarketDayStamp;

  const CommandCenterAccessState({
    required this.tier,
    this.isDoorUnlocked = false,
    this.plusDaysRemaining = 0,
    this.lastMarketDayStamp,
  });
}

class DisciplineCounterService {
  static const String _kKeyPlusDays = 'cc_plus_days';
  static const String _kKeyLastStamp = 'cc_last_stamp';
  static const String _kKeyFreeDoor = 'cc_free_door_unlocked'; // Session only usually, but maybe persist? User said "4 taps gate". 

  final SharedPreferences _prefs;

  DisciplineCounterService(this._prefs);

  static Future<DisciplineCounterService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return DisciplineCounterService(prefs);
  }

  /// Main access check
  CommandCenterAccessState getAccessState(CommandCenterTier userTier) {
    if (userTier == CommandCenterTier.elite) {
       return const CommandCenterAccessState(tier: CommandCenterTier.elite, isDoorUnlocked: true);
    }
    
    if (userTier == CommandCenterTier.plus) {
       int remaining = _prefs.getInt(_kKeyPlusDays) ?? 5; // Default start at 5? Or 0? "show 5..0"
       // If logic is "5 market-open days counter"
       return CommandCenterAccessState(
         tier: CommandCenterTier.plus,
         isDoorUnlocked: true, // Plus is always "unlocked" but has limited Coherence visibility? 
         // Wait, user says: "PLUS: show 5..0 based on Discipline Counter".
         // "PLUS: 5 market-open days counter (decrements only on market-open days...)"
         plusDaysRemaining: remaining
       );
    }

    // Free
    // "FREE: 4 taps gate; when opened, all content remains frosted + upsell CTA."
    // We treat local persistence for "door unlocked" as session-based or persistent? 
    // Usually "door" is session. But let's verify. 
    // "existing 4-tap door stays; just display state"
    // We'll rely on a calling controller for the 4-tap logic or store it here?
    // Let's store it here for simplicity.
    bool unlocked = _prefs.getBool(_kKeyFreeDoor) ?? false;
    return CommandCenterAccessState(tier: CommandCenterTier.free, isDoorUnlocked: unlocked);
  }

  /// Called when app is opened (or Command Center is opened).
  /// Validates if we should decrement the Plus counter.
  Future<void> checkAndDecrementPlus(CommandCenterTier userTier) async {
    if (userTier != CommandCenterTier.plus) return;

    final now = DateTime.now();
    if (!_isMarketOpenDay(now)) return;

    final todayStamp = _computeMarketDayStamp(now);
    final lastStamp = _prefs.getString(_kKeyLastStamp);

    if (lastStamp == todayStamp) {
      // Already counted for today
      return;
    }

    // New market day
    int current = _prefs.getInt(_kKeyPlusDays) ?? 5; // Start at 5?
    if (current > 0) {
      current--;
      await _prefs.setInt(_kKeyPlusDays, current);
      await _prefs.setString(_kKeyLastStamp, todayStamp);
    }
  }
  
  // Free Door Logic
  Future<void> setFreeDoorUnlocked(bool unlocked) async {
     await _prefs.setBool(_kKeyFreeDoor, unlocked);
  }

  /// Reset counter (e.g. for testing or refill)
  Future<void> resetPlusCounter() async {
    await _prefs.setInt(_kKeyPlusDays, 5);
    await _prefs.remove(_kKeyLastStamp);
  }

  // --- Helpers ---

  // Simple ISO date YYYY-MM-DD
  String _computeMarketDayStamp(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
  }

  bool _isMarketOpenDay(DateTime date) {
    // Weekday check (Mon=1, Fri=5)
    // TODO: Connect to real market status if available.
    // For now: Mon-Fri.
    if (date.weekday >= 1 && date.weekday <= 5) {
       return true;
    }
    return false;
  }
}
