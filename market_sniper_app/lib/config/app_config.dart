class AppConfig {
  // Dart Define ensures these can be set at build time
  // D45.H2 Canonical PROD URL (SSOT)
  static const String _canonicalProdUrl = 'https://marketsniper-api-3ygzdvszba-uc.a.run.app';

  // Dart Define ensures these can be set at build time
  // RELEASE GUARD: If kReleaseMode, IGNORE env var and force PROD.
  static String get apiBaseUrl {
    if (const bool.fromEnvironment('dart.vm.product')) {
       return _canonicalProdUrl;
    }
    // Debug/Profile: Allow override or default to emulator
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000', // Default to Android Emulator -> Localhost
    );
  }

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
