import 'package:shared_preferences/shared_preferences.dart';

class ViralTeaserStore {
  static const String _kFirstOpenKey = 'viral_teaser_first_open_seen';
  static const String _kLastShareKey = 'viral_teaser_last_share_ts';

  static Future<bool> isFirstOpenSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFirstOpenKey) ?? false;
  }

  static Future<void> markFirstOpenSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFirstOpenKey, true);
  }

  static Future<DateTime?> getLastShareTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(_kLastShareKey);
    return ts != null ? DateTime.parse(ts) : null;
  }

  static Future<void> markShared() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastShareKey, DateTime.now().toIso8601String());
  }

  static Future<bool> canShare() async {
    final last = await getLastShareTime();
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= 7;
  }
}
