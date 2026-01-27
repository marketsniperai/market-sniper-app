import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/system_health_snapshot.dart';
import '../config/app_config.dart';

class ProviderStatusIndicator extends StatelessWidget {
  final SystemHealthSnapshot snapshot;

  const ProviderStatusIndicator({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    // If no providers known, hidden or generic?
    // "Any provider DOWN -> overall = DEGRADED" implies we check providers.
    // If empty, assume OK or hide?
    // Let's assume OK if snapshot is Nominal, else Degraded?
    // Actually, rely on snapshot.status logic from Repo for color?
    // No, snapshot.status mixes in Staleness/Sources.
    // We want STRICT UPSTREAM PROVIDER status.

    // Calculate local provider health
    bool anyDown = false;
    bool anyDegraded = false;

    if (snapshot.providers.isNotEmpty) {
      anyDown = snapshot.providers.values
          .any((v) => v.contains('DOWN') || v.contains('FAIL'));
      anyDegraded = snapshot.providers.values
          .any((v) => v.contains('DEGRADED') || v.contains('LAG'));
    } else {
      // Fallback if providers map empty but status is degraded?
      if (snapshot.status == HealthStatus.degraded) anyDegraded = true;
    }

    String label = "LIVE";
    Color color = AppColors.stateLive;

    if (anyDown) {
      // "Any provider DOWN -> overall = DEGRADED" per prompt Logic rules.
      // But Color Canon says: "DOWN -> Red (rare)".
      // Prompt says: "Precedence: Any provider DOWN -> overall = DEGRADED".
      // This matches Amber.
      // But then it says "DOWN -> Red". When is it DOWN?
      // Presumably if ALL are down? Or if "Core" is down?
      // Let's stick to prompt: "Any provider DOWN -> overall = DEGRADED" (Amber).
      // So Red only if specifically flagged as critical outage?
      // Or maybe prompt meant "Provider Status: DOWN" is Red.
      // Let's implement:
      // All Down -> DOWN (Red)
      // Some Down -> DEGRADED (Amber)
      // None Down -> LIVE (Green)

      bool allDown = snapshot.providers.isNotEmpty &&
          snapshot.providers.values.every((v) => v.contains('DOWN'));
      if (allDown) {
        label = "DOWN";
        color = AppColors.stateLocked; // Red
      } else {
        label = "DEGRADED";
        color = AppColors.stateStale; // Amber
      }
    } else if (anyDegraded) {
      label = "DEGRADED";
      color = AppColors.stateStale;
    }

    // Founder Check for Tap
    final isFounder = AppConfig.isFounderBuild;

    return GestureDetector(
      onTap: isFounder ? () => _showBreakdown(context) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              "PROVIDERS: $label",
              style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RobotoMono'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBreakdown(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        title: const Text("Provider Breakdown (Founder)",
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (snapshot.providers.isEmpty)
              const Text("No detailed provider data.",
                  style: TextStyle(color: AppColors.textDisabled)),
            ...snapshot.providers.entries.map((e) {
              Color c = AppColors.stateLive;
              if (e.value.contains('DOWN')) c = AppColors.stateLocked;
              if (e.value.contains('DEGRADED')) c = AppColors.stateStale;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    Text(e.value,
                        style:
                            TextStyle(color: c, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE",
                style: TextStyle(color: AppColors.neonCyan)),
          )
        ],
      ),
    );
  }
}
