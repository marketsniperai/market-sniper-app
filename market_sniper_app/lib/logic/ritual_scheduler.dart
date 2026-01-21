import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

enum RitualStatus {
  ready,
  cooldown,
  notInWindow,
}

class RitualDefinition {
  final String id;
  final String label;
  final int targetHour;
  final int targetMinute;
  final int windowMinutes;

  const RitualDefinition({
    required this.id,
    required this.label,
    required this.targetHour,
    required this.targetMinute,
    required this.windowMinutes,
  });
}

class RitualScheduler {
  static final RitualScheduler _instance = RitualScheduler._internal();
  factory RitualScheduler() => _instance;
  RitualScheduler._internal();

  static const List<RitualDefinition> rituals = [
    RitualDefinition(
        id: 'MORNING_BRIEFING',
        label: 'Morning Briefing',
        targetHour: 9,
        targetMinute: 20,
        windowMinutes: 15),
    RitualDefinition(
        id: 'MARKET_SUMMARY',
        label: 'Market Summary',
        targetHour: 16,
        targetMinute: 5,
        windowMinutes: 15),
    RitualDefinition(
        id: 'HOW_I_DID_TODAY',
        label: 'How I Did Today',
        targetHour: 16,
        targetMinute: 10,
        windowMinutes: 15),
  ];

  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Initialize scheduler and load prefs.
  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
    } catch (_) {
      // Ignore if already initialized
    }
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Get current status of a ritual.
  RitualStatus checkStatus(RitualDefinition ritual) {
    if (!_initialized) return RitualStatus.notInWindow;

    final nowEt = _getNowEt();
    final dayId = _getDayId(nowEt);
    
    // 1. Check Cooldown
    final lastFiredDay = _prefs?.getString('ritual_${ritual.id}_last_day');
    if (lastFiredDay == dayId) {
      return RitualStatus.cooldown;
    }

    // 2. Check Window
    final targetTime = tz.TZDateTime(
      nowEt.location,
      nowEt.year,
      nowEt.month,
      nowEt.day,
      ritual.targetHour,
      ritual.targetMinute,
    );
    
    final windowEnd = targetTime.add(Duration(minutes: ritual.windowMinutes));

    // Eligible if: targetTime <= now <= windowEnd
    if (nowEt.isAfter(targetTime) && nowEt.isBefore(windowEnd)) {
      return RitualStatus.ready;
    }
    
    // Also handle case where "isAfter(targetTime)" includes "isAt(targetTime)" logic practically
    // and strictly speaking we might want exact minute check, but "now" is granular.
    // Ensure we handle edge cases like just opened. 
    // Actually, simple comparison is fine.
    
    return RitualStatus.notInWindow;
  }
  
  /// Mark a ritual as fired for today.
  Future<void> markFired(RitualDefinition ritual) async {
    if (!_initialized) await init();
    final nowEt = _getNowEt();
    final dayId = _getDayId(nowEt);
    await _prefs?.setString('ritual_${ritual.id}_last_day', dayId);
  }

  /// Helper: Get current ET time.
  tz.TZDateTime _getNowEt() {
    try {
      final detroit = tz.getLocation('America/Detroit');
      return tz.TZDateTime.now(detroit);
    } catch (e) {
      // Fallback to UTC if timezone fail (shouldn't happen if initialized)
      final now = DateTime.now().toUtc();
      // Mock location or just return UTC as "ET" for safety to avoid crash
      return tz.TZDateTime.utc(now.year, now.month, now.day, now.hour, now.minute);
    }
  }

  String _getDayId(tz.TZDateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
  
  /// Get next occurrence string (for UI)
  String getNextTimeString(RitualDefinition ritual) {
     final nowEt = _getNowEt();
     // If passed today, assume tomorrow? 
     // UI just asks for "Next: 09:20 ET". 
     // We can just return the static time.
     final h = ritual.targetHour.toString().padLeft(2,'0');
     final m = ritual.targetMinute.toString().padLeft(2,'0');
     return "$h:$m ET";
  }
}
