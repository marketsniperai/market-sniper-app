import 'package:shared_preferences/shared_preferences.dart';

class PlusUnlockStore {
  static const String _kCountKey = 'plus_cc_opens_count';
  static const String _kLastDateKey = 'plus_cc_last_date'; // YYYYMMDD
  static const int _kTarget = 5;

  static Future<int> getCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kCountKey) ?? 0;
  }

  static Future<String?> getLastDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastDateKey);
  }

  static Future<void> increment(String dateId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kCountKey) ?? 0;
    
    // No cap logic here, engine handles checks. Just storage.
    // Actually, cap is harmless.
    if (current >= _kTarget) return;

    await prefs.setInt(_kCountKey, current + 1);
    await prefs.setString(_kLastDateKey, dateId);
  }

  static Future<bool> isUnlocked() async {
    final count = await getCount();
    return count >= _kTarget;
  }
}
