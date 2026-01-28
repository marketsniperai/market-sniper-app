import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:path_provider/path_provider.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;

class SessionThreadMemoryStore {
  static final SessionThreadMemoryStore _instance =
      SessionThreadMemoryStore._internal();
  factory SessionThreadMemoryStore() => _instance;
  SessionThreadMemoryStore._internal();

  File? _file;
  Map<String, dynamic> _data = {
    'day_id': '',
    'last_updated_utc': '',
    'turns': <Map<String, String>>[],
  };

  bool _initialized = false;

  /// Initialize the store and load data.
  Future<void> init() async {
    if (_initialized) return;
    try {
      // tz.initializeTimeZones();
    } catch (_) {
      // Ignore if already initialized
    }

    if (kIsWeb) {
      print('MEMORY_STORE: WEB_FALLBACK_IN_MEMORY (SessionThreadMemoryStore)');
      _initialized = true;
      return;
    }

    try {
      final directory = await getApplicationSupportDirectory();
      _file = File('${directory.path}/session_thread_memory_store.json');
      await _load();
      _initialized = true;
    } catch (e) {
      print('SessionThreadMemoryStore init error: $e');
    }
  }

  Future<void> _load() async {
    if (_file != null && await _file!.exists()) {
      try {
        final content = await _file!.readAsString();
        // Degrade check: if massive, nuke it
        if (content.length > 5000) {
          await clear();
          return;
        }
        final Map<String, dynamic> loaded = jsonDecode(content);
        _data = loaded;

        // Type safety for turns
        if (!_data.containsKey('turns') || _data['turns'] is! List) {
          _data['turns'] = <Map<String, String>>[];
        } else {
          // Ensure items are Map<String, String>
          final rawList = _data['turns'] as List;
          _data['turns'] =
              rawList.map((e) => Map<String, String>.from(e)).toList();
        }

        await _checkReset();
      } catch (e) {
        await clear();
      }
    }
  }

  String _getCurrentDayId() {
    try {
      // final detroit = tz.getLocation('America/Detroit');
      // final nowEt = tz.TZDateTime.now(detroit);
      final nowEt = DateTime.now().toUtc().subtract(const Duration(hours: 5));

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
      await clear();
    }
  }

  Future<void> append(String role, String text) async {
    if (!_initialized) await init();
    await _checkReset();

    final turn = {
      'role': role,
      'text': text,
      'ts_utc': DateTime.now().toUtc().toIso8601String(),
    };

    List<Map<String, String>> turns =
        _data['turns'] as List<Map<String, String>>;
    turns.add(turn);

    _data['last_updated_utc'] = DateTime.now().toUtc().toIso8601String();
    _data['day_id'] = _getCurrentDayId();

    await _enforceCapsAndSave();
  }

  Future<void> clear() async {
    _data = {
      'day_id': _getCurrentDayId(),
      'last_updated_utc': DateTime.now().toUtc().toIso8601String(),
      'turns': <Map<String, String>>[],
    };
    if (_file != null) {
      // Just overwrite with empty data to avoid file open issues if we deleted
      // but strictly speaking deleting is fine too. Let's write empty.
      await _save();
    }
  }

  Future<void> _save() async {
    if (_file == null) return;
    try {
      await _file!.writeAsString(jsonEncode(_data));
    } catch (e) {
      print('SessionThreadMemoryStore save error: $e');
    }
  }

  Future<void> _enforceCapsAndSave() async {
    if (_file == null) return;

    List<Map<String, String>> turns =
        _data['turns'] as List<Map<String, String>>;

    // 1. Cap Count to 12
    while (turns.length > 12) {
      turns.removeAt(0); // Remove oldest
    }

    String jsonStr = jsonEncode(_data);

    // 2. Cap Size to 4096
    while (utf8.encode(jsonStr).length > 4096 && turns.isNotEmpty) {
      turns.removeAt(0);
      jsonStr = jsonEncode(_data);
    }

    try {
      await _file!.writeAsString(jsonStr);
    } catch (e) {
      print('SessionThreadMemoryStore save error: $e');
    }
  }

  List<Map<String, String>> getTurns() {
    if (_data['turns'] is List) {
      return (_data['turns'] as List)
          .map((e) => Map<String, String>.from(e))
          .toList();
    }
    return [];
  }
}
