import 'package:shared_preferences/shared_preferences.dart';

class FounderRouterStore {
  static const String _kKey = 'founder_router_last_destination';
  static const String _valWarRoom = 'war_room';
  static const String _valCommandCenter = 'command_center';

  static Future<String> getLastDestination() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kKey) ?? _valWarRoom; // Default to War Room
  }

  static Future<void> saveDestination(String destination) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, destination);
  }

  static String get warRoom => _valWarRoom;
  static String get commandCenter => _valCommandCenter;
}
