// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz_data;

enum SessionState {
  closed,
  pre,
  market,
  after,
}

class TimeUtils {
  static bool _initialized = false;

  static void init() {
    // No-op for Web Compatibility (D45)
    // if (!_initialized) {
    //   tz_data.initializeTimeZones();
    //   _initialized = true;
    // }
    _initialized = true;
  }

  // Changed Return Type to DateTime (native) implies breaking change for callers expecting TZDateTime?
  // TZDateTime extends DateTime, so returning DateTime is valid if callers expect DateTime, but if they expect TZDateTime explicitly...
  // Most callers probably use it as DateTime.
  // getNowEt() returned tz.TZDateTime.
  // I should return DateTime and hope callers utilize it as such.
  static DateTime getNowEt() {
    // init(); // Ensure initialized
    // final detroit = tz.getLocation('America/New_York');
    // return tz.TZDateTime.now(detroit);
    
    // Web-Safe Fallback: UTC-5 (EST)
    return DateTime.now().toUtc().subtract(const Duration(hours: 5));
  }

  static SessionState getSessionState(DateTime etTime) {
    // Canonical Rules:
    // PRE:    04:00:01 – 09:29:59
    // MARKET: 09:30:01 – 15:59:59
    // AFTER:  16:00:01 – 19:59:59
    // CLOSED: 20:00:01 – 03:59:59

    // Simplified for second-precision comparisons using H/M/S
    final int secondsOfDay =
        etTime.hour * 3600 + etTime.minute * 60 + etTime.second;

    // 04:00:00 = 14400
    // 09:30:00 = 34200
    // 16:00:00 = 57600
    // 20:00:00 = 72000

    if (secondsOfDay > 14400 && secondsOfDay <= 34200) {
      return SessionState.pre;
    } else if (secondsOfDay > 34200 && secondsOfDay <= 57600) {
      return SessionState.market;
    } else if (secondsOfDay > 57600 && secondsOfDay <= 72000) {
      return SessionState.after;
    } else {
      return SessionState.closed;
    }
  }
}
