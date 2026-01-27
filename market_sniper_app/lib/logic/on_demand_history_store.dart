import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
      tz.initializeTimeZones();
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
  String _getCurrentDayId() {
    try {
      final detroit = tz.getLocation('America/Detroit'); // ET
      final nowEt = tz.TZDateTime.now(detroit);
      final effectiveDate =
          nowEt.hour < 4 ? nowEt.subtract(const Duration(days: 1)) : nowEt;

      return "${effectiveDate.year}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}";
    } catch (e) {
      final now = DateTime.now().toUtc();
      return "${now.year}-${now.month}-${now.day}";
    }
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
