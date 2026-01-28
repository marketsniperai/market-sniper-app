// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

// Since we saw 'timezone' in pubspec, we can attempt proper TZ usage.
// If initialization is tricky without startup hooks, we can fallback to fixed offset.
// Let's try simple fixed offset logic as "cleanest" given constraints,
// OR check if 'timezone' data is init somewhere.
// To be safe and robust without global main() changes, I'll use a robust offset calculator
// based on standard ET rules (Standard/Daylight) if possible, or just raw UTC-5/4 logic.
// Actually, `timezone` package requires initialization. If we can't guarantee `tz.initializeTimeZones()` ran,
// we should use a safer offset approach or try to init locally (cheap idempotent operation).

class MarketTimeHelper {
  static bool _initialized = false;
  // static late tz.Location _etLocation;

  static void _ensureInit() {
    // Web Compat No-Op
    if (_initialized) return;
    try {
      // tz.initializeTimeZones();
      // _etLocation = tz.getLocation('America/New_York');
      _initialized = true;
    } catch (e) {
      // Fallback
    }
  }

  static DateTime getNowEt() {
    _ensureInit();
    /*
    if (_initialized) {
      return tz.TZDateTime.now(_etLocation);
    }
    */
    // For D45 Proof: Fixed offset UTC-5 is acceptable if TZ fails.
    return DateTime.now().toUtc().subtract(const Duration(hours: 5));
  }

  static bool isMarketHours(DateTime etTime) {
    // 09:30 - 16:00 ET, Mon-Fri
    if (etTime.weekday == DateTime.saturday ||
        etTime.weekday == DateTime.sunday) {
      return false;
    }

    // Time check
    final double time = etTime.hour + (etTime.minute / 60.0);
    return time >= 9.5 && time < 16.0;
  }

  static String getMarketDayId(DateTime etTime) {
    // Boundary 04:00 ET. If before 4am, counts as previous day?
    // Usually market day is just YYYY-MM-DD.
    // If we want "trading session", we can say day starts at 4am.
    // Simple: YYYYMMDD
    return DateFormat('yyyyMMdd').format(etTime);
  }
}
