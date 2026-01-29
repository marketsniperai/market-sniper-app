
class EliteRitualState {
  final bool enabled;
  final bool visible;
  final int? countdownMinutes;

  const EliteRitualState({
    required this.enabled,
    required this.visible,
    this.countdownMinutes,
  });
}

class EliteRitualPolicyResolver {
  // Canonical Windows (Mirrors os_elite_ritual_policy_v1.json)
  static const Map<String, Map<String, dynamic>> _rules = {
    "morning_briefing": {
      "type": "daily",
      "start": "09:20",
      "end": "09:50",
      "visibility": "always"
    },
    "mid_day_report": {
      "type": "daily",
      "start": "12:30",
      "end": "13:00",
      "visibility": "always"
    },
    "market_resumed": {
      "type": "daily",
      "start": "16:05",
      "end": "16:35",
      "visibility": "always"
    },
    "how_i_did_today": {
      "type": "daily",
      "start": "16:10",
      "end": "16:40",
      "visibility": "always"
    },
    "how_you_did_today": {
      "type": "daily",
      "start": "16:15",
      "end": "16:45",
      "visibility": "always"
    },
    "sunday_setup": {
      "type": "weekly",
      "start_day": 7, // Sunday
      "start_time": "20:00",
      "end_day": 1, // Monday
      "end_time": "09:00",
      "visibility": "window_only",
      "countdown_trigger": 60
    }
  };

  /// Returns the state of a specific ritual based on the current time (UTC).
  /// Converts to US/Eastern automatically.
  EliteRitualState resolve(String ritualId, DateTime nowUtc) {
    // 1. Convert to US/Eastern
    final nowEt = _toEastern(nowUtc);

    final rule = _rules[ritualId];
    if (rule == null) {
      // Unknown ritual: default to disabled/invisible or safe fallback
      return const EliteRitualState(enabled: false, visible: false);
    }

    bool isInWindow = false;
    int? countdown;

    final type = rule['type'] as String;

    if (type == 'daily') {
      isInWindow = _checkDailyWindow(
          nowEt, rule['start'] as String, rule['end'] as String);
    } else if (type == 'weekly') {
      final result = _checkWeeklyWindow(
        nowEt,
        rule['start_day'] as int,
        rule['start_time'] as String,
        rule['end_day'] as int,
        rule['end_time'] as String,
        rule['countdown_trigger'] as int?,
      );
      isInWindow = result.isInWindow;
      countdown = result.countdown;
    }

    final visibilityRule = rule['visibility'] as String;
    bool visible = true;
    if (visibilityRule == 'window_only') {
      visible = isInWindow;
    }

    return EliteRitualState(
      enabled: isInWindow,
      visible: visible,
      countdownMinutes: countdown,
    );
  }

  // --- Helpers ---

  bool _checkDailyWindow(DateTime now, String start, String end) {
    final nowTime = now.hour * 60 + now.minute;
    final startTime = _parseMinutes(start);
    final endTime = _parseMinutes(end);

    if (startTime <= endTime) {
      return nowTime >= startTime && nowTime <= endTime;
    } else {
      // Crossing midnight
      return nowTime >= startTime || nowTime <= endTime;
    }
  }

  ({bool isInWindow, int? countdown}) _checkWeeklyWindow(
      DateTime now, int startDay, String startTimeStr, int endDay, String endTimeStr, int? countdownTrigger) {
    // ISO 8601: Mon=1, Sun=7
    final currentDay = now.weekday;
    
    // We need to determine if we are strictly between Start(Day+Time) and End(Day+Time)
    // This handles wrapping (Sun -> Mon).
    
    // Convert current time to "minutes since Monday 00:00" for easier comparison?
    // Or just check logic. 
    
    // Logic for Sun 20:00 -> Mon 09:00
    // Active if:
    // (Day == Sun AND Time >= 20:00) OR (Day == Mon AND Time <= 09:00)
    
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _parseMinutes(startTimeStr);
    final endMinutes = _parseMinutes(endTimeStr);

    bool active = false;
    
    if (startDay == 7 && endDay == 1) {
        // Special Sunday -> Monday wrap
        if (currentDay == 7 && nowMinutes >= startMinutes) active = true;
        if (currentDay == 1 && nowMinutes <= endMinutes) active = true;
    } else {
        // Standard non-wrapping case (simplification for now, extend if needed)
         if (currentDay == startDay) {
             if (currentDay == endDay) {
                 active = nowMinutes >= startMinutes && nowMinutes <= endMinutes;
             } else {
                 active = nowMinutes >= startMinutes;
             }
         } else if (currentDay == endDay) {
             active = nowMinutes <= endMinutes;
         } else if (currentDay > startDay && currentDay < endDay) {
             active = true;
         }
    }
    
    int? countdownVal;
    
    if (active && countdownTrigger != null) {
        // Calculate remaining minutes
        // We know end is Mon 09:00.
        // If today is Mon, end is today.
        // If today is Sun, end is tomorrow.
        
        DateTime endDt = DateTime(now.year, now.month, now.day, 
             _parseHour(endTimeStr), _parseMinute(endTimeStr));
             
        if (currentDay == 7 && endDay == 1) {
            endDt = endDt.add(const Duration(days: 1)); // End is tomorrow
        }
        
        // If currentDay == 1, endDt is today, correct.
        
        final diff = endDt.difference(now);
        final minutesLeft = diff.inMinutes;

        if (minutesLeft > 0 && minutesLeft <= countdownTrigger) {
            countdownVal = minutesLeft;
        }
    }
    
    return (isInWindow: active, countdown: countdownVal);
  }

  int _parseMinutes(String hm) {
    final parts = hm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
  
  int _parseHour(String hm) {
      return int.parse(hm.split(':')[0]);
  }
  int _parseMinute(String hm) {
      return int.parse(hm.split(':')[1]);
  }

  // Manual DST for US/Eastern
  // Starts: 2nd Sunday in March
  // Ends: 1st Sunday in November
  DateTime _toEastern(DateTime utc) {
    // 1. Calculate Standard Time (UTC-5)
    final est = utc.subtract(const Duration(hours: 5));
    
    // 2. Check strict DST rules for the given year
    if (_isDst(est)) {
       return utc.subtract(const Duration(hours: 4));
    }
    return est;
  }

  bool _isDst(DateTime dt) {
    final year = dt.year;
    
    // 2nd Sunday March
    final march1 = DateTime(year, 3, 1);
    // Find first Sunday

    // Actually ISO weekday: Mon=1, Sun=7.
    // If Mar1 is Sun, weekday=7. target is 7. diff = 0.
    // If Mar1 is Mon, weekday=1. target is 7. diff = 6.
    // First Sunday = 1 + (7 - weekday + 7) % 7?
    // 7 - 1(Mon) = 6. 1+6=7 (Strict correct).
    // 7 - 7(Sun) = 0. 1+0=1 (Strict correct).
    
    final firstSunMarch = march1.add(Duration(days: (7 - march1.weekday) % 7)); 
    // Wait, if Mar 1 is Sunday (7), (7-7)%7 = 0. Add 0. Date is Mar 1. First Sunday is Mar 1. Correct.
    
    final secondSunMarch = firstSunMarch.add(const Duration(days: 7));
    // DST Starts 2am
    final dstStart = DateTime(year, 3, secondSunMarch.day, 2, 0);

    // 1st Sunday Nov
    final nov1 = DateTime(year, 11, 1);
    final firstSunNov = nov1.add(Duration(days: (7 - nov1.weekday) % 7));
    // DST Ends 2am
    final dstEnd = DateTime(year, 11, firstSunNov.day, 2, 0);

    return dt.isAfter(dstStart) && dt.isBefore(dstEnd);
  }
}
