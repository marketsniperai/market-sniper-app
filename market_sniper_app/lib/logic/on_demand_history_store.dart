import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;

class OnDemandHistoryItem {
  final String ticker;
  final String timestampUtc;

  OnDemandHistoryItem({required this.ticker, required this.timestampUtc});

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'timestampUtc': timestampUtc,
      };

  factory OnDemandHistoryItem.fromJson(Map<String, dynamic> json) {
    return OnDemandHistoryItem(
      ticker: json['ticker'] as String,
      timestampUtc: json['timestampUtc'] as String,
    );
  }
}

class OnDemandHistoryStore {
  static final OnDemandHistoryStore _instance =
      OnDemandHistoryStore._internal();
  factory OnDemandHistoryStore() => _instance;
  OnDemandHistoryStore._internal();

  File? _file;
  Map<String, dynamic> _data = {
    'day_id': '', // For 04:00 ET Reset
    'items': <dynamic>[], // List of OnDemandHistoryItem JSON
  };

  bool _initialized = false;
  static const int _maxItems = 5;

  Future<void> init() async {
    if (_initialized) return;
    try {
      // tz.initializeTimeZones();
    } catch (_) {}

    try {
      final directory = await getApplicationSupportDirectory();
      _file = File('${directory.path}/on_demand_history_store.json');
      await _load();
      _initialized = true;
    } catch (e) {
      // debugPrint('OnDemandHistoryStore init error: $e');
    }
  }

  /// Calculates the current "Day ID" based on 04:00 ET boundary.
  /// (Replicated from DayMemoryStore for canonical consistency)
  /// Calculates the current "Day ID" based on 04:00 ET boundary.
  /// Uses manual DST logic to match Backend ZoneInfo without adding external deps.
  String _getCurrentDayId() {
    final nowUtc = DateTime.now().toUtc();
    final isDst = _isUSDaylightSavings(nowUtc);
    
    // ET is UTC-5 (STD) or UTC-4 (DST)
    final offset = isDst ? const Duration(hours: 4) : const Duration(hours: 5);
    final nowEt = nowUtc.subtract(offset);

    // Business Day Rule: Day starts at 04:00 ET.
    // If < 04:00, it belongs to previous calendar day.
    final effectiveDate =
        nowEt.hour < 4 ? nowEt.subtract(const Duration(days: 1)) : nowEt;

    return "${effectiveDate.year}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}";
  }

  /// Determines if US Daylight Savings Time is active for a given UTC time.
  /// Rule: Starts 2nd Sunday in March @ 02:00 Local (07:00 UTC Std).
  ///       Ends 1st Sunday in November @ 02:00 Local (06:00 UTC Dst / 07:00 UTC Std? No, 2am DST becomes 1am STD).
  ///       DST is UTC-4. STD is UTC-5.
  ///       Transition forward: 2am ET (Std) -> 3am ET (Dst). Occurs at 07:00 UTC.
  ///       Transition back: 2am ET (Dst) -> 1am ET (Std). Occurs at 06:00 UTC.
  bool _isUSDaylightSavings(DateTime utcTime) {
    final year = utcTime.year;

    // DST Start: 2nd Sunday in March
    // Find March 1st weekday
    // 1st Sunday will be 1 + (7-weekday)%7 ? No.
    // DateTime.sunday is 7.
    final mar1 = DateTime.utc(year, 3, 1);
    // days to first sunday = (7 - mar1.weekday + 7) % 7 ?
    // If Mar 1 is Sun(7) -> 0 days ? No, if Mar 1 is Sunday, it is the First Sunday.
    // daysToAdd = (DateTime.sunday - mar1.weekday + 7) % 7.
    // If Sun(7): (7-7)%7 = 0. Correct.
    // If Mon(1): (7-1)%7 = 6. Mar 1 + 6 = Mar 7. Correct.
    int daysToFirstSunMar = (DateTime.sunday - mar1.weekday + 7) % 7;
    int firstSunMarDay = 1 + daysToFirstSunMar;
    int secondSunMarDay = firstSunMarDay + 7;
    
    // DST Starts at 07:00 UTC (2am EST)
    final dstStart = DateTime.utc(year, 3, secondSunMarDay, 7);

    // DST End: 1st Sunday in November
    final nov1 = DateTime.utc(year, 11, 1);
    int daysToFirstSunNov = (DateTime.sunday - nov1.weekday + 7) % 7;
    int firstSunNovDay = 1 + daysToFirstSunNov;
    
    // DST Ends at 06:00 UTC (2am EDT becomes 1am EST)
    // Wait. 2am EDT is 6am UTC. 
    // At that moment, clocks fall back to 1am EST.
    // So any time BEFORE 06:00 UTC on that day is DST.
    final dstEnd = DateTime.utc(year, 11, firstSunNovDay, 6);

    return utcTime.isAfter(dstStart) && utcTime.isBefore(dstEnd);
  }

  Future<void> _checkReset() async {
    final currentDayId = _getCurrentDayId();
    if (_data['day_id'] != currentDayId) {
      _data['items'] = <dynamic>[];
      _data['day_id'] = currentDayId;
      await _save();
    }
  }

  Future<void> _load() async {
    if (_file != null && await _file!.exists()) {
      try {
        final content = await _file!.readAsString();
        final Map<String, dynamic> loaded = jsonDecode(content);
        _data = loaded;

        if (!_data.containsKey('items')) {
          _data['items'] = [];
        }

        await _checkReset();
      } catch (e) {
        await clear();
      }
    } else {
      // Init day_id if first run
      _data['day_id'] = _getCurrentDayId();
    }
  }

  Future<void> record({required String ticker}) async {
    if (!_initialized) await init();
    await _checkReset();

    final cleanTicker = ticker.trim().toUpperCase();
    final nowStr = DateTime.now().toUtc().toIso8601String();

    List<dynamic> rawItems = _data['items'];

    // Dedupe: Remove existing occurrence
    rawItems.removeWhere((item) => item['ticker'] == cleanTicker);

    // Add to front
    rawItems.insert(0, {
      'ticker': cleanTicker,
      'timestampUtc': nowStr,
    });

    // Cap at 5
    if (rawItems.length > _maxItems) {
      _data['items'] = rawItems.sublist(0, _maxItems);
    } else {
      _data['items'] = rawItems;
    }

    await _save();
  }

  List<OnDemandHistoryItem> getRecent() {
    if (!_initialized) return [];

    // We assume _checkReset is called on record/init, but strictly we could check here too
    // Keeping it lightweight for UI READs.

    List<dynamic> rawItems = _data['items'] ?? [];
    return rawItems.map((json) => OnDemandHistoryItem.fromJson(json)).toList();
  }

  Future<void> clear() async {
    _data = {
      'day_id': _getCurrentDayId(),
      'items': [],
    };
    if (_file != null && await _file!.exists()) {
      await _file!.delete();
    }
  }

  Future<void> _save() async {
    if (_file == null) return;
    try {
      await _file!.writeAsString(jsonEncode(_data));
    } catch (e) {
      // debugPrint('OnDemandHistoryStore save error: $e');
    }
  }
}
