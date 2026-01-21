import 'package:shared_preferences/shared_preferences.dart';

class TrialStateStore {
  static const String _kInstallTime = 'ms_install_timestamp_utc';
  static const String _kOpenCount = 'ms_trial_open_count';
  static const String _kLastDayId = 'ms_last_counted_market_day_id';
  static const String _kStatus = 'ms_trial_status';

  // Reads
  Future<Map<String, dynamic>> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'install_u': prefs.getString(_kInstallTime),
      'count': prefs.getInt(_kOpenCount) ?? 0,
      'last_day': prefs.getString(_kLastDayId),
      'status': prefs.getString(_kStatus) ?? 'ACTIVE',
    };
  }

  // Writes
  Future<void> setInstallTimeIfNeeded(String isoUtc) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kInstallTime)) {
      await prefs.setString(_kInstallTime, isoUtc);
    }
  }

  Future<void> updateCount(int newCount, String dayId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kOpenCount, newCount);
    await prefs.setString(_kLastDayId, dayId);
  }

  Future<void> setStatusComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStatus, 'COMPLETE');
  }
}
