import '../../config/app_config.dart';
import '../models/premium/premium_matrix_model.dart';
import 'trial_engine.dart';
import 'try_me_scheduler.dart';

class PremiumStatusResolver {
  static PremiumTier get currentTier {
    if (AppConfig.isFounderBuild) return PremiumTier.founder;
    
    // Check if Trial is Complete
    if (TrialEngine.isComplete) {
      // If Try-Me Active, effectively Plus/Elite? 
      // For D45, we just say "Guest" but maybe unlock features via other checks.
      // Matrix shows features based on tiers.
      // For now, return GUEST.
      return PremiumTier.guest;
    }
    
    // Default
    return PremiumTier.guest; 
  }

  static String get trialProgressString {
    if (AppConfig.isFounderBuild) return "FOUNDER BYPASS";
    
    if (TrialEngine.isComplete) {
      // Post-trial state
      if (TryMeScheduler.isTryMeWindowNow()) {
        return "TRY-ME ACTIVE";
      }
      return "TRIAL COMPLETE";
    }
    
    // Active Trial
    return "${TrialEngine.currentCount}/3 Market Opens";
  }
  
  static bool get tryMeEligible {
    return TrialEngine.isComplete;
  }
}
