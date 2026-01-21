import 'dart:convert';
import 'package:flutter/services.dart';

enum PremiumTier { guest, plus, elite, founder }
enum FeatureStatus { included, locked, limited, progress }

class PremiumFeatureRow {
  final String key;
  final String label;
  final String detail;
  final Map<PremiumTier, FeatureStatus> availability;
  final Map<PremiumTier, String> limits;
  final String? dynamicValueKey;

  const PremiumFeatureRow({
    required this.key,
    required this.label,
    required this.detail,
    required this.availability,
    required this.limits,
    this.dynamicValueKey,
  });

  factory PremiumFeatureRow.fromJson(Map<String, dynamic> json) {
    // Parse availability map
    final availMap = <PremiumTier, FeatureStatus>{};
    final rawAvail = json['availability'] as Map<String, dynamic>;
    for (var k in rawAvail.keys) {
      final tier = _parseTier(k);
      final status = _parseStatus(rawAvail[k]);
      if (tier != null) availMap[tier] = status;
    }

    // Parse limits map
    final limitsMap = <PremiumTier, String>{};
    if (json['limits'] != null) {
      final rawLimits = json['limits'] as Map<String, dynamic>;
      for (var k in rawLimits.keys) {
        final tier = _parseTier(k);
        if (tier != null) limitsMap[tier] = rawLimits[k].toString();
      }
    }

    return PremiumFeatureRow(
      key: json['key'],
      label: json['label'],
      detail: json['detail'],
      availability: availMap,
      limits: limitsMap,
      dynamicValueKey: json['dynamic_value'],
    );
  }

  static PremiumTier? _parseTier(String s) {
    switch (s.toUpperCase()) {
      case 'GUEST': return PremiumTier.guest;
      case 'PLUS': return PremiumTier.plus;
      case 'ELITE': return PremiumTier.elite;
      case 'FOUNDER': return PremiumTier.founder;
      default: return null;
    }
  }

  static FeatureStatus _parseStatus(String s) {
    switch (s.toUpperCase()) {
      case 'INCLUDED': return FeatureStatus.included;
      case 'LOCKED': return FeatureStatus.locked;
      case 'LIMITED': return FeatureStatus.limited;
      case 'PROGRESS': return FeatureStatus.progress;
      default: return FeatureStatus.locked;
    }
  }
}

class PremiumMatrixModel {
  static Future<List<PremiumFeatureRow>> load() async {
    // Mock load matching SSOT `outputs/os/os_premium_feature_matrix.json`
    return [
      _row("trial_progress", "Trial (Market Opens)", "Full OS access for 3 market opens",
        {"GUEST":"INCLUDED","PLUS":"INCLUDED","ELITE":"INCLUDED","FOUNDER":"INCLUDED"}, {}, dynamicValue: "trial_opens_progress"),
      _row("watchlist", "Watchlist", "Follow tickers + quick actions", 
        {"GUEST":"INCLUDED","PLUS":"INCLUDED","ELITE":"INCLUDED","FOUNDER":"INCLUDED"}, {}),
      _row("on_demand", "On-Demand Lookup", "Global context lookup (Source Ladder)", 
        {"GUEST":"LOCKED","PLUS":"LIMITED","ELITE":"INCLUDED","FOUNDER":"INCLUDED"}, {"PLUS":"10/day"}),
      _row("elite_overlay", "Elite Overlay", "Mentor surface + explain protocols", 
        {"GUEST":"LOCKED","PLUS":"LIMITED","ELITE":"INCLUDED","FOUNDER":"INCLUDED"}, {}),
      _row("explain", "Explain (Context)", "Explain from OS snapshot / on-demand result", 
        {"GUEST":"LOCKED","PLUS":"INCLUDED","ELITE":"INCLUDED","FOUNDER":"INCLUDED"}, {}),
      _row("news_digest", "News Digest", "Top 8 impact digest + flip expand", 
        {"GUEST":"INCLUDED","PLUS":"INCLUDED","ELITE":"INCLUDED","FOUNDER":"INCLUDED"}, {}),
      _row("economic_calendar", "Economic Calendar", "Daily/Weekly macro + earnings impact", 
        {"GUEST":"INCLUDED","PLUS":"INCLUDED","ELITE":"INCLUDED","FOUNDER":"INCLUDED"}, {}),
      _row("try_me_hour", "Try-Me Hour", "Mon 09:20–10:20 ET access window", 
        {"GUEST":"INCLUDED","PLUS":"INCLUDED","ELITE":"INCLUDED","FOUNDER":"INCLUDED"}, {}),
      _row("command_center", "Command Center", "Hidden OS surface (context mysteries)", 
        {"GUEST":"LOCKED","PLUS":"PROGRESS","ELITE":"INCLUDED","FOUNDER":"INCLUDED"}, {"PLUS":"Unlock at Day 5 (no reset)"}),
      _row("history_memory", "History & Memory", "Recent context + session memory", 
        {"GUEST":"LOCKED","PLUS":"INCLUDED","ELITE":"INCLUDED","FOUNDER":"INCLUDED"}, {}),
    ];
  }

  static PremiumFeatureRow _row(
      String key, 
      String label, 
      String detail, 
      Map<String,String> avail, 
      Map<String,String>? limits,
      {String? dynamicValue}) {
    return PremiumFeatureRow.fromJson({
      "key": key,
      "label": label,
      "detail": detail,
      "availability": avail,
      "limits": limits,
      "dynamic_value": dynamicValue
    });
  }
}
