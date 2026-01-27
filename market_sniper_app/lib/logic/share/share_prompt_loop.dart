import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../widgets/share/share_booster_sheet.dart';
import 'share_library_store.dart'; // Reuse logging Shim from D45.09 if needed, or simple debug

class SharePromptLoop {
  static const String _kLastPromptTimeKey = 'ms_share_prompt_last_time';
  static const int _kCooldownMinutes = 10;

  static Future<void> maybeShow(BuildContext context) async {
    // 1. Policy Checks
    if (AppConfig.isFounderBuild) {
      return; // Prompt: "Must not appear if ... FOUNDER"
    }

    // Cooldown
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getInt(_kLastPromptTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastTime < _kCooldownMinutes * 60 * 1000) {
      // In cooldown
      return;
    }

    // 2. Show Sheet
    // We log "PROMPT_SHOWN"
    await _logEvent("PROMPT_SHOWN", {"context": "post_export"});
    await prefs.setInt(_kLastPromptTimeKey, now);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareBoosterSheet(
        onSave: () {
          _logEvent("CTA_CLICKED", {"key": "SAVE"});
          Navigator.pop(context);
        },
        onShare: () {
          _logEvent("CTA_CLICKED", {"key": "SHARE_NATIVE"});
          Navigator.pop(
              context); // It's just a booster, actual share was already attempted or is re-triggerable
        },
        onUpgrade: () {
          _logEvent("CTA_CLICKED", {"key": "UPGRADE_ELITE"});
          Navigator.pop(context);
          // Nav logic would go here
        },
        showUpgrade: true, // Assuming not Elite for MVP/Guest
      ),
    ).then((_) {
      // On Dismiss
      _logEvent("PROMPT_DISMISSED", {});
    });
  }

  static Future<void> _logEvent(
      String event, Map<String, dynamic> extras) async {
    // Reusing D45.09 Store logging for consistency locally
    await ShareLibraryStore.logEvent(event, extras);
  }
}
