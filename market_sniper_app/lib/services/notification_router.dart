import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/war_room_screen.dart';
import '../screens/ritual_preview_screen.dart';

import '../guards/access_policy.dart'; // Founder Law

class NotificationRouter {
  static void route(GlobalKey<NavigatorState> navigatorKey, String? payload) {
    if (payload == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Access Check logic (Enforcing Founder Law)
    final hasAccess = AccessPolicy.canAccessRituals;

    // Payload routing
    if (payload == "ritual:briefing") {
      if (hasAccess) {
        // Morning Briefing -> Dashboard (Home)
        navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false);
      } else {
        navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (_) => const RitualPreviewScreen(
                title: "Morning Briefing",
                description:
                    "Institutional context for the opening bell. Align your execution with daily structural levels.")));
      }
    } else if (payload == "ritual:aftermarket") {
      if (hasAccess) {
        // Aftermarket -> War Room (Ledger)
        navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false);
        // Then push War Room
        navigatorKey.currentState
            ?.push(MaterialPageRoute(builder: (_) => const WarRoomScreen()));
      } else {
        navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (_) => const RitualPreviewScreen(
                title: "Aftermarket Closure",
                description:
                    "Finalize your daily ledger. Review conflicting signals and prepare for the next session.")));
      }
    }
  }
}
