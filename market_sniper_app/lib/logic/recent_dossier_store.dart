import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class RecentDossierEntry {
  final String ticker;
  final String timeframe;
  final String timestampUtc; // When it was saved (now)
  final String asOfUtc; // From payload
  final String reliabilityState; // From payload/logic
  final Map<String, dynamic> rawPayload;

  RecentDossierEntry({
    required this.ticker,
    required this.timeframe,
    required this.timestampUtc,
    required this.asOfUtc,
    required this.reliabilityState,
    required this.rawPayload,
  });

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'timeframe': timeframe,
        'timestampUtc': timestampUtc,
        'asOfUtc': asOfUtc,
        'reliabilityState': reliabilityState,
        'rawPayload': rawPayload,
      };

  factory RecentDossierEntry.fromJson(Map<String, dynamic> json) {
    return RecentDossierEntry(
      ticker: json['ticker'] as String,
      timeframe: json['timeframe'] as String,
      timestampUtc: json['timestampUtc'] as String,
      asOfUtc: json['asOfUtc'] as String,
      reliabilityState: json['reliabilityState'] as String,
      rawPayload: json['rawPayload'] as Map<String, dynamic>,
    );
  }
}

class RecentDossierStore {
  static final RecentDossierStore _instance = RecentDossierStore._internal();
  factory RecentDossierStore() => _instance;
  RecentDossierStore._internal();

  File? _file;
  List<RecentDossierEntry> _entries = [];
  bool _initialized = false;
  static const int _maxItems = 10;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final directory = await getApplicationSupportDirectory();
      _file = File('${directory.path}/recent_dossiers_v1.json');
      await _load();
      _initialized = true;
    } catch (e) {
      debugPrint('RecentDossierStore init error: $e');
    }
  }

  Future<void> _load() async {
    if (_file != null && await _file!.exists()) {
      try {
        final content = await _file!.readAsString();
        final List<dynamic> loaded = jsonDecode(content);
        _entries = loaded.map((e) => RecentDossierEntry.fromJson(e)).toList();
      } catch (e) {
        _entries = [];
      }
    }
  }

  Future<void> record({
    required String ticker,
    required String timeframe,
    required String asOfUtc,
    required String reliabilityState,
    required Map<String, dynamic> rawPayload,
  }) async {
    if (!_initialized) await init();

    final cleanTicker = ticker.trim().toUpperCase();
    final entry = RecentDossierEntry(
      ticker: cleanTicker,
      timeframe: timeframe,
      timestampUtc: DateTime.now().toUtc().toIso8601String(),
      asOfUtc: asOfUtc,
      reliabilityState: reliabilityState,
      rawPayload: rawPayload,
    );

    // Dedupe: Remove existing exact match (Ticker + Timeframe)
    // If user re-runs SPY DAILY, we want to update it and move to front.
    _entries.removeWhere((e) => e.ticker == cleanTicker && e.timeframe == timeframe);

    // Add to front
    _entries.insert(0, entry);

    // Cap
    if (_entries.length > _maxItems) {
      _entries = _entries.sublist(0, _maxItems);
    }

    await _save();
  }

  List<RecentDossierEntry> getRecent() {
    return List.unmodifiable(_entries);
  }

  Future<void> clear() async {
    _entries = [];
    if (_file != null && await _file!.exists()) {
      await _file!.delete();
    }
  }

  Future<void> _save() async {
    if (_file == null) return;
    try {
      final jsonList = _entries.map((e) => e.toJson()).toList();
      await _file!.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('RecentDossierStore save error: $e');
    }
  }
}
