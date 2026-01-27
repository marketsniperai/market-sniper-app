import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HumanModeService extends ChangeNotifier {
  static final HumanModeService _instance = HumanModeService._internal();
  factory HumanModeService() => _instance;
  HumanModeService._internal();

  bool _enabled = true; // Default ON (Human-Friendly by default)
  bool _isInitialized = false;

  bool get enabled => _enabled;

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    // Default to true if not set
    _enabled = prefs.getBool('human_mode_enabled') ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('human_mode_enabled', value);
  }
}
