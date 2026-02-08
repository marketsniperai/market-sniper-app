import 'package:flutter/foundation.dart'; // kDebugMode

class AppConfig {
  // Dart Define ensures these can be set at build time
  // D45.H2 Canonical PROD URL (SSOT)
  static const String _canonicalProdUrl =
      'https://marketsniper-api-3ygzdvszba-uc.a.run.app';



  // D45.HF05 Auth Gateway (Org Policy Bypass)
  // If set, this takes precedence over Cloud Run direct URL.
  static String get apiGatewayUrl {
     return const String.fromEnvironment('API_GATEWAY_URL', defaultValue: '');
  }
  
  // Route B: API Key for Gateway
  static String get founderApiKey {
      const env = String.fromEnvironment('FOUNDER_API_KEY', defaultValue: '');
      if (env.isEmpty && kDebugMode) return 'mz_founder_888'; // D56.01.2A: Auto-Unlock for Local Debug
      return env;
  }

  // Dart Define ensures these can be set at build time
  // RELEASE GUARD: If kReleaseMode, IGNORE env var and force PROD.
  // Dart Define ensures these can be set at build time
  // RELEASE GUARD: If kReleaseMode, IGNORE env var and force PROD.
  static String get apiBaseUrl {
    // 0. Manual Override (Highest Priority check)
    // If running via dev_ritual/flutter run --dart-define=API_BASE_URL=... use it.
    const explicitUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (explicitUrl.isNotEmpty) return explicitUrl;

    // 1. Gateway Preference
    final gateway = apiGatewayUrl;
    if (gateway.isNotEmpty) {
        return gateway.startsWith('http') ? gateway : "https://$gateway";
    }

    if (const bool.fromEnvironment('dart.vm.product')) {
      return _canonicalProdUrl;
    }
    
    // Debug/Profile Default:
    if (kIsWeb) {
      if (kDebugMode) return _canonicalProdUrl; // D61.2D: Web uses PROD to avoid localhost CORS/Port issues
    }

    // Default Fallback
    return _canonicalProdUrl;
  }
  
  static void printStartupLog() {
     if (kDebugMode && isNetAuditEnabled) {
         print("APP_CONFIG: apiBaseUrl=$apiBaseUrl");
         print("APP_CONFIG: netAuditEnabled=$isNetAuditEnabled");
     }
  }
  
  static bool get isFounderBuild {
    // Verified: Removed blanket debug override (D61.x.06B)
    return const bool.fromEnvironment(
      'FOUNDER_BUILD',
      defaultValue: false,
    );
  }

  // D37.07 Refresh Governance
  static const int dashboardAutoRefreshSeconds = 60;
  static const int dashboardErrorBackoffSeconds = 120;
  static const int manualRefreshCooldownSeconds = 10;

  // D38.08 War Room Refresh Governance
  static const int warRoomAutoRefreshSeconds = 60;
  static const int warRoomBackoffSeconds = 120;
  static const int warRoomManualRefreshCooldownSeconds = 15;

  // DXX.WELCOME.02 Invite Gate Config
  static bool get inviteEnabled {
    // Default ON for production. Can be toggled via build flag if needed.
    // const bool defaultVal = true; // REMOVED (Unused)
    if (isFounderBuild) {
      return false; // Optional: Default OFF for Founder if desired, but User said 'bypass' logic handles it.
    }
    // User request: "AppConfig.inviteEnabled (default ON for production, OFF for Founder builds if desired)"
    // Let's stick to true default but allow override.
    return true;
  }

  // Pattern: Starts with MS-, followed by 5 alphanumeric chars.
  // Example: MS-A1B2C
  static const String invitePattern = r'^MS-[A-Z0-9]{5}$';

  static bool get inviteBypassForFounder => true;

  // D56.01.5: War Room Network Policy Guard
  // Tracks if the War Room is active to enforce Snapshot-Only fetching.
  static bool _warRoomActive = false;
  static bool get isWarRoomActive => _warRoomActive;
  static void setWarRoomActive(bool active) {
    if (_warRoomActive != active) {
        if (kDebugMode && isNetAuditEnabled) print("WAR_ROOM_STATE: active=$active");
        _warRoomActive = active;
    }
  }

  // D56.01.5: Network Audit Log Toggle
  // Default: FALSE (Quiet). Enable via --dart-define=NET_AUDIT_ENABLED=true
  static bool get isNetAuditEnabled {
    if (!kDebugMode) return false;
    return const bool.fromEnvironment('NET_AUDIT_ENABLED', defaultValue: false);
  }
}
