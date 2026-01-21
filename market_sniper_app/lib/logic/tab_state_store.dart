import 'package:shared_preferences/shared_preferences.dart';

class TabStateStore {
  static const String _key = 'ms_last_tab_index';
  static const int _defaultIndex = 0;
  static const int _maxIndex = 4; // 0..4

  /// Should be called early in app startup or main_layout initState
  Future<int> loadLastTabIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_key) ?? _defaultIndex;
      
      // Safety bounds check
      if (index < 0 || index > _maxIndex) {
        return _defaultIndex;
      }
      return index;
    } catch (e) {
      // Fail safe to home
      return _defaultIndex;
    }
  }

  Future<void> saveLastTabIndex(int index) async {
    // Validate before write
    if (index < 0 || index > _maxIndex) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, index);
    } catch (e) {
      // Silent fail
    }
  }
}
