import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchlistStore extends ChangeNotifier {
  static final WatchlistStore _instance = WatchlistStore._internal();
  factory WatchlistStore() => _instance;
  WatchlistStore._internal();

  static const String _storageKey = 'market_sniper_watchlist_v1';
  List<String> _tickers = [];
  bool _initialized = false;

  List<String> get tickers => List.unmodifiable(_tickers);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey);
      if (list != null) {
        _tickers = list;
      }
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint("WatchlistStore init error: $e");
    }
  }

  Future<bool> addTicker(String symbol) async {
    if (!_initialized) await init();
    
    final normalized = symbol.trim().toUpperCase();
    if (_tickers.contains(normalized)) {
      return false; // Already exists (Dedupe)
    }

    _tickers.add(normalized);
    await _save();
    notifyListeners();
    return true; // Added
  }

  Future<void> removeTicker(String symbol) async {
    if (!_initialized) await init();
    
    final normalized = symbol.trim().toUpperCase();
    _tickers.remove(normalized);
    await _save();
    notifyListeners();
  }

  bool contains(String symbol) {
    return _tickers.contains(symbol.trim().toUpperCase());
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _tickers);
    } catch (e) {
      debugPrint("WatchlistStore save error: $e");
    }
  }
}
