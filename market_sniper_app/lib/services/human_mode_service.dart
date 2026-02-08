import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class HumanModeService extends ChangeNotifier {
  static final HumanModeService _instance = HumanModeService._internal();
  factory HumanModeService() => _instance;
  HumanModeService._internal();

  bool _enabled = true; // Default ON (Human-Friendly by default)
  bool _isInitialized = false;

  bool get enabled => _enabled;

  Future<void> init() async {
    if (_isInitialized) return;
    
    // HF-1 Law: Public builds receive Human Mode (High-Context) by default and cannot opt-out.
    // Founder builds retain the switch state from preferences.
    if (AppConfig.isFounderBuild) {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool('human_mode_enabled') ?? true;
    } else {
      _enabled = true; // Always Human First for Public
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    // Public: Cannot disable Human Mode (HF-1)
    if (!AppConfig.isFounderBuild && !value) return;

    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('human_mode_enabled', value);
  }
}
