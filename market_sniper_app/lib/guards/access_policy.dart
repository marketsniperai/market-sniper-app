import '../config/app_config.dart';

class AccessPolicy {
  /// FOUNDER LAW:
  /// If the build is a Founder Build, ALL features are always-on.
  /// No gating, no locks, no upsell previews.
  static bool get founderAlwaysOn => AppConfig.isFounderBuild;

  /// Determines if the user can access Rituals (Briefing/Aftermarket).
  /// Currently enforces Founder Law.
  static bool get canAccessRituals => founderAlwaysOn;

  /// Determines if the user can access Premium content.
  /// Currently enforces Founder Law.
  static bool get canAccessPremium => founderAlwaysOn;
}
