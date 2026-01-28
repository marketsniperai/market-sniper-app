import '../config/app_config.dart';
import 'elite_access_window_controller.dart'; // D45.07
import 'plus_unlock_engine.dart'; // D41.XX

// D47.HF31: Standardized Definitions
enum OnDemandTier { 
  free, // Basic Access (Most Gating)
  plus, // Mid Access (Unlock Future, Tactical. Lock Mentor)
  elite // Full Access (Unlock All)
}

class OnDemandTierResolver {
  /// HF31: Resolve current user tier based on multiple entitlement controllers.
  /// Hierarchy: Founder > Elite (Time-based or Entitled) > Plus (Daily Unlock) > Free
  static Future<OnDemandTier> resolve() async {
    // 1. Founder Bypass (Always Elite+)
    if (AppConfig.isFounderBuild) {
      return OnDemandTier.elite;
    }

    // 2. Check Elite Access (Time-Based / Try-Me / Subscription)
    // EliteAccessWindowController handles logic for "Try-Me" and subscription checks if wired.
    final eliteResult = await EliteAccessWindowController.resolve();
    if (eliteResult.isUnlocked) {
      return OnDemandTier.elite;
    }

    // 3. Check Plus Access (Daily Step Unlock)
    // PlusUnlockEngine determines if user has completed "5 check" ritual.
    final isPlusUnlocked = await PlusUnlockEngine.isUnlocked();
    if (isPlusUnlocked) {
      return OnDemandTier.plus;
    }

    // 4. Default to Free
    return OnDemandTier.free;
  }
}
