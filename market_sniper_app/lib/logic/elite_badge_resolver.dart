import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// D49: Elite Badge Resolver (Frontend Logic)
/// Deterministic resolver for Badge State based on Event Types.
class EliteBadgeResolver {
  
  static BadgeResult resolve(String eventType, Map<String, dynamic>? details, bool isQuietHour) {
     
     // Quiet Hour Logic: If quiet, downgrade notifications to badges or suppress?
     // Policy says: Quiet Hours Exceptions = CRITICAL_ALERT.
     // For now, if quiet hour, we set 'showNotification' to false unless critical.
     // But we always show Badge.
     
     bool allowNotif = !isQuietHour;

     switch (eventType) {
        case "ELITE_BRIEFING_READY":
           return BadgeResult(
               hasBadge: true,
               text: "BRIEF",
               color: AppColors.neonCyan,
               notificationBody: allowNotif ? "Morning Briefing Ready" : null
           );
           
        case "ELITE_MIDDAY_READY":
           return BadgeResult(
               hasBadge: true,
               text: "RPT",
               color: AppColors.neonCyan,
               notificationBody: allowNotif ? "Mid-Day Report Ready" : null
           );
           
        case "ELITE_MARKET_SUMMARY_READY":
           return BadgeResult(
               hasBadge: true,
               text: "SUM",
               color: AppColors.neonCyan,
               notificationBody: allowNotif ? "Market Summary Ready" : null
           );
           
        case "ELITE_FREE_WINDOW_OPEN":
           return BadgeResult(
               hasBadge: true,
               text: "FREE",
               color: AppColors.stateLive,
               notificationBody: allowNotif ? "Elite Free Window Open" : null
           );
           
        case "ELITE_FREE_WINDOW_5MIN":
           return BadgeResult(
               hasBadge: true,
               text: "5m",
               color: AppColors.stateStale,
               notificationBody: allowNotif ? "5 Minutes Remaining" : null
           );
           
        case "ELITE_FREE_WINDOW_CLOSED":
           // Clear badge usually? Or show "Locked"?
           // Policy: badge=false
           return BadgeResult.empty();

        case "ELITE_RITUAL_CLOSING":
           return BadgeResult(
               hasBadge: true,
               text: "!",
               color: AppColors.stateStale,
               notificationBody: null // Just badge
           );
           
        default:
           // Fallback for generic available
           if (eventType == "ELITE_RITUAL_AVAILABLE") {
               return BadgeResult(
                   hasBadge: true,
                   text: "1",
                   color: AppColors.neonCyan,
                   notificationBody: allowNotif ? "New Ritual Available" : null
               );
           }
           return BadgeResult.empty();
     }
  }
}

class BadgeResult {
  final bool hasBadge;
  final String? text;
  final Color? color;
  final String? notificationBody;
  
  BadgeResult({required this.hasBadge, this.text, this.color, this.notificationBody});
  
  factory BadgeResult.empty() => BadgeResult(hasBadge: false);
}
