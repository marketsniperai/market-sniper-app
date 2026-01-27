// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // If needed for local storage

class CommandCenterCard {
  final String title;
  final List<String> drivers;
  final List<String> evidenceBadges;
  final String? osFocus;
  final List<String> descriptionBullets; // For fallback/other sections
  final List<String> badges; // Generic badges

  CommandCenterCard({
    required this.title,
    this.drivers = const [],
    this.evidenceBadges = const [],
    this.osFocus,
    this.descriptionBullets = const [],
    this.badges = const [],
  });
}

class CommandCenterData {
  final List<CommandCenterCard> osFocusCards;
  final List<CommandCenterCard> confidenceDescriptions;
  final List<String> learnings;
  final List<Map<String, String>> artifacts;

  CommandCenterData({
    required this.osFocusCards,
    required this.confidenceDescriptions,
    required this.learnings,
    required this.artifacts,
  });
}

class CommandCenterBuilder {
  static Future<CommandCenterData> build() async {
    // 1. OS Focus — Today’s Key Moves
    final focusCards = [
      CommandCenterCard(
          title: "Rates Sensitivity Repricing",
          drivers: [
            "Drivers: 10Y Yield Velocity > 2σ",
            "Sector Sensitivity: Utilities / Real Estate Lagging"
          ],
          evidenceBadges: ["PULSE", "OVERLAY", "PROVIDER_LIVE"],
          osFocus: "Monitoring cross-asset confirmation for persistence."),
      CommandCenterCard(
          title: "Volatility Compression Watch",
          drivers: [
            "Drivers: VIX Term Structure Flattening",
            "Gamma: Dealer Long Bias increasing"
          ],
          evidenceBadges: ["EVIDENCE MEMORY", "PROXY_ESTIMATED"],
          osFocus: "Tracking regime stability near key thresholds."),
    ];

    // 2. Confidence
    final confidence = [
      CommandCenterCard(
          title: "Sector Coverage Integrity",
          badges: ["COVERAGE", "PROVIDER_LIVE"],
          descriptionBullets: ["11/11 Sectors active", "Data freshness > 98%"]),
      CommandCenterCard(
          title: "Volatility Proxy",
          badges: ["PROXY_ESTIMATED"],
          descriptionBullets: ["VIX implied derived from spot correlation"]),
    ];

    // 3. Learnings
    final learnings = [
      "Noise filters refined on intraday spikes.",
      "Persistence layer optimized for low-latency.",
      "Institutional cadence alignment improved."
    ];

    // 4. Artifacts
    final artifacts = [
      {"name": "Briefing.json", "status": "SYNCED"},
      {"name": "Aftermarket.json", "status": "PENDING"},
      {"name": "PulseState.log", "status": "LIVE"},
      {"name": "OneRule.md", "status": "CANON"},
    ];

    return CommandCenterData(
      osFocusCards: focusCards,
      confidenceDescriptions: confidence,
      learnings: learnings,
      artifacts: artifacts,
    );
  }
}
