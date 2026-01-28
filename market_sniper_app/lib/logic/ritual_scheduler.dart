import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

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
      // tz.initializeTimeZones();
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
    final targetTime = DateTime.utc( // Using UTC as base for ET object calc
      nowEt.year,
      nowEt.month,
      nowEt.day,
      ritual.targetHour,
      ritual.targetMinute,
    ).subtract(const Duration(hours: 0)); // No shift needed if nowEt is already shifted? 
    // Wait. nowEt is DateTIme with hour shifted.
    // So targetTime should be constructed with same "local" components.
    
    final targetTimeConstructed = DateTime(
       nowEt.year, nowEt.month, nowEt.day, ritual.targetHour, ritual.targetMinute
    ); // Treated as local comparison object

    final windowEnd = targetTimeConstructed.add(Duration(minutes: ritual.windowMinutes));

    // Eligible if: targetTime <= now <= windowEnd
    if (nowEt.isAfter(targetTimeConstructed) && nowEt.isBefore(windowEnd)) {
      return RitualStatus.ready;
    }

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
  DateTime _getNowEt() {
    try {
      // final detroit = tz.getLocation('America/Detroit');
      // return tz.TZDateTime.now(detroit);
      return DateTime.now().toUtc().subtract(const Duration(hours: 5));
    } catch (e) {
      // Fallback
      return DateTime.now().toUtc().subtract(const Duration(hours: 5));
    }
  }

  String _getDayId(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Get next occurrence string (for UI)
  String getNextTimeString(RitualDefinition ritual) {
    final h = ritual.targetHour.toString().padLeft(2, '0');
    final m = ritual.targetMinute.toString().padLeft(2, '0');
    return "$h:$m ET";
  }
}
