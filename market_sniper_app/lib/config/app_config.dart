class AppConfig {
  // Dart Define ensures these can be set at build time
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Default to Android Emulator -> Localhost
  );

  static const bool isFounderBuild = bool.fromEnvironment(
    'FOUNDER_BUILD',
    defaultValue: false,
  );

  // D37.07 Refresh Governance
  static const int dashboardAutoRefreshSeconds = 60;
  static const int dashboardErrorBackoffSeconds = 120;
  static const int manualRefreshCooldownSeconds = 10;
  
  // D38.08 War Room Refresh Governance
  static const int warRoomAutoRefreshSeconds = 60;
  static const int warRoomBackoffSeconds = 120;
  static const int warRoomManualRefreshCooldownSeconds = 15;
}
