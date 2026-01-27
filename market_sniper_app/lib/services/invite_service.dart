import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class InviteService {
  static final InviteService _instance = InviteService._internal();
  factory InviteService() => _instance;
  InviteService._internal();

  static const String _prefKey = 'invite_code';
  static const String _ledgerKey = 'invite_ledger_list';
  static const int _maxLedgerLines = 50; // Keep it light for Prefs

  // State
  String? _loadedCode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _loadedCode = prefs.getString(_prefKey);
  }

  String? get currentCode => _loadedCode;

  // Validation Logic
  String normalize(String code) {
    // Upper + Trim + Collapse Spaces
    return code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  bool isValid(String code) {
    if (code.isEmpty) return false;
    final RegExp regex = RegExp(AppConfig.invitePattern);
    return regex.hasMatch(code);
  }

  bool canBypass() {
    return AppConfig.isFounderBuild && AppConfig.inviteBypassForFounder;
  }

  // Submit Code
  Future<bool> submitCode(String rawCode) async {
    final code = normalize(rawCode);
    final valid = isValid(code);
    final bypass = canBypass();

    // Log Attempt
    await _appendToLedger(
      event: 'CODE_SUBMIT',
      valid: valid,
      codePrefix: _getPrefix(code),
      reason: valid
          ? 'VALID_PATTERN'
          : (bypass ? 'FOUNDER_BYPASS' : 'INVALID_PATTERN'),
    );

    if (valid || bypass) {
      _loadedCode = code;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
      return true;
    }

    return false;
  }

  // Terms Logic
  Future<void> recordTermsAcceptance(String termsHash) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = DateTime.now().toUtc().toIso8601String();

    // Update Props
    await prefs.setString('terms_hash', termsHash);
    await prefs.setString('accepted_terms_at_utc', ts);

    // Log
    await _appendToLedger(
        event: "TERMS_ACCEPT", valid: true, reason: "HASH:$termsHash");
  }

  Future<bool> isGateSatisfied() async {
    // Invite Valid OR Bypass
    if (AppConfig.inviteEnabled) {
      if (_loadedCode == null) return false;
      if (!isValid(_loadedCode!) && !canBypass()) return false;
    }

    // Terms Accepted? (Check pref directly or assume handled by routing logic?
    // User request: "Ensure /startup is guarded: if inviteEnabled && !founderBypass && !inviteValid"
    // Terms check is usually separate, but let's include basic check if needed.
    // For now, Guard will call this.
    return true;
  }

  // Ledgering (Universal: Uses SharedPreferences List)
  Future<void> _appendToLedger(
      {required String event,
      required bool valid,
      String? codePrefix,
      String? reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> lines = prefs.getStringList(_ledgerKey) ?? [];

      final entry = {
        "ts_utc": DateTime.now().toUtc().toIso8601String(),
        "event": event,
        "invite_code_prefix": codePrefix ?? "NONE",
        "valid": valid,
        "reason": reason ?? "UNKNOWN",
        "app_version": "1.0.0",
        "invite_normalized": _loadedCode ?? "NONE",
      };

      lines.add(jsonEncode(entry));

      // Enforce Limit
      if (lines.length > _maxLedgerLines) {
        lines = lines.sublist(lines.length - _maxLedgerLines);
      }

      await prefs.setStringList(_ledgerKey, lines);
    } catch (e) {
      debugPrint("InviteLedger Error: $e");
    }
  }

  String _getPrefix(String code) {
    if (code.length > 3) return code.substring(0, 3);
    return code;
  }

  // Read Ledger (For War Room)
  Future<List<Map<String, dynamic>>> getLedgerTail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lines = prefs.getStringList(_ledgerKey) ?? [];

      return lines.reversed.take(20).map((l) {
        try {
          return jsonDecode(l) as Map<String, dynamic>;
        } catch (_) {
          return <String, dynamic>{};
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
