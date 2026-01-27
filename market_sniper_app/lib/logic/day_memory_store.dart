import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DayMemoryStore {
  static final DayMemoryStore _instance = DayMemoryStore._internal();
  factory DayMemoryStore() => _instance;
  DayMemoryStore._internal();

  File? _file;
  Map<String, dynamic> _data = {
    'day_id': '',
    'last_updated_utc': '',
    'bullets': <String>[],
  };

  bool _initialized = false;

  /// Initialize the store and load data.
  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
    } catch (_) {
      // Ignore if already initialized
    }

    if (kIsWeb) {
      print('MEMORY_STORE: WEB_FALLBACK_IN_MEMORY (DayMemoryStore)');
      _initialized = true;
      return;
    }

    try {
      final directory = await getApplicationSupportDirectory();
      _file = File('${directory.path}/day_memory_store.json');
      await _load();
      _initialized = true;
    } catch (e) {
      print('DayMemoryStore init error: $e');
      // Degrade to in-memory only (or broken) but don't crash
    }
  }

  Future<void> _load() async {
    if (_file != null && await _file!.exists()) {
      try {
        final content = await _file!.readAsString();
        // Degrade check: if already massive, nuking it is safer than trying to parse
        if (content.length > 5000) {
          await clear();
          return;
        }
        final Map<String, dynamic> loaded = jsonDecode(content);
        _data = loaded;

        // Ensure structure matches
        if (!_data.containsKey('bullets') || _data['bullets'] is! List) {
          _data['bullets'] = <String>[];
        }

        await _checkReset();
      } catch (e) {
        // Corrupt file -> reset
        await clear();
      }
    }
  }

  /// Calculates the current "Day ID" based on 04:00 ET boundary.
  /// If now is 2026-01-20 03:59 ET, day_id is 2026-01-19.
  /// If now is 2026-01-20 04:01 ET, day_id is 2026-01-20.
  String _getCurrentDayId() {
    try {
      final detroit = tz.getLocation('America/Detroit'); // ET
      final nowEt = tz.TZDateTime.now(detroit);
      // If before 4AM, we are effectively in the "previous day"
      final effectiveDate =
          nowEt.hour < 4 ? nowEt.subtract(const Duration(days: 1)) : nowEt;

      return "${effectiveDate.year}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}";
    } catch (e) {
      // Fallback to UTC if TZ fails
      final now = DateTime.now().toUtc();
      // Rough approximation for fallback
      return "${now.year}-${now.month}-${now.day}";
    }
  }

  Future<void> _checkReset() async {
    final currentDayId = _getCurrentDayId();
    if (_data['day_id'] != currentDayId) {
      _data['bullets'] = <String>[];
      _data['day_id'] = currentDayId;
      await _save(); // Save the reset state
    }
  }

  Future<void> append(String bullet) async {
    if (!_initialized) await init();

    await _checkReset(); // Ensure we are in the right day

    List<dynamic> bullets = _data['bullets'];
    bullets.add(bullet);

    _data['last_updated_utc'] = DateTime.now().toUtc().toIso8601String();
    _data['day_id'] = _getCurrentDayId(); // Update day_id to be sure

    await _enforceCapAndSave();
  }

  Future<void> clear() async {
    _data = {
      'day_id': _getCurrentDayId(),
      'last_updated_utc': DateTime.now().toUtc().toIso8601String(),
      'bullets': <String>[],
    };
    if (_file != null) {
      if (await _file!.exists()) {
        await _file!.delete();
      }
    }
  }

  Future<void> _save() async {
    if (_file == null) return;
    try {
      await _file!.writeAsString(jsonEncode(_data));
    } catch (e) {
      print('DayMemoryStore save error: $e');
    }
  }

  Future<void> _enforceCapAndSave() async {
    if (_file == null) return;

    String jsonStr = jsonEncode(_data);
    List<dynamic> bullets = _data['bullets'];

    // Prune until under 4096 bytes
    while (utf8.encode(jsonStr).length > 4096 && bullets.isNotEmpty) {
      bullets.removeAt(0); // Remove oldest
      jsonStr = jsonEncode(_data);
    }

    try {
      await _file!.writeAsString(jsonStr);
    } catch (e) {
      // Write failed?
      print('DayMemoryStore save error: $e');
    }
  }

  List<String> getBullets() {
    if (_data['bullets'] is List) {
      return List<String>.from(_data['bullets']);
    }
    return [];
  }
}
