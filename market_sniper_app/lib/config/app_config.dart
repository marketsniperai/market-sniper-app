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
}
