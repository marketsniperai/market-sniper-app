import 'package:flutter/material.dart';
import 'elite_ritual_button.dart';
import '../logic/elite_ritual_policy_resolver.dart';

class EliteRitualGrid extends StatelessWidget {
  final Function(String)? onRitualTap;

  const EliteRitualGrid({super.key, this.onRitualTap});

  @override
  Widget build(BuildContext context) {
    // Resolve states based on current UTC time
    final resolver = EliteRitualPolicyResolver();
    final now = DateTime.now().toUtc();
    
    final morningState = resolver.resolve("morning_briefing", now);
    final middayState = resolver.resolve("mid_day_report", now);
    final resumedState = resolver.resolve("market_resumed", now);
    final iDidState = resolver.resolve("how_i_did_today", now);
    final youDidState = resolver.resolve("how_you_did_today", now);
    final sundayState = resolver.resolve("sunday_setup", now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: 3 Buttons
          Row(
            children: [
              Expanded(
                child: EliteRitualButton(
                  time: "09:20 AM",
                  label: "Morning Briefing",
                  isDisabled: !morningState.enabled, // Dynamic
                  onTap: () => onRitualTap?.call("morning_briefing"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: EliteRitualButton(
                  time: "12:30 PM",
                  label: "Mid-Day Report",
                  isDisabled: !middayState.enabled, // Dynamic
                  onTap: () => onRitualTap?.call("mid_day_report"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: EliteRitualButton(
                  time: "04:05 PM",
                  label: "Market Resumed",
                  isDisabled: !resumedState.enabled, // Dynamic
                  onTap: () => onRitualTap?.call("market_resumed"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: 2 Buttons + Sunday
          Row(
            children: [
              Expanded(
                child: EliteRitualButton(
                  time: "04:10 PM",
                  label: "How I Did Today",
                  isDisabled: !iDidState.enabled, // Dynamic
                  onTap: () => onRitualTap?.call("how_i_did_today"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: EliteRitualButton(
                  time: "04:15 PM",
                  label: "How You Did Today",
                  isDisabled: !youDidState.enabled, // Dynamic
                  onTap: () => onRitualTap?.call("how_you_did_today"),
                ),
              ),
              const SizedBox(width: 8),
              // Slot 6: Sunday Setup
              Expanded(
                child: Opacity(
                  opacity: sundayState.visible ? 1.0 : 0.0, // Hide if not visible
                  child: IgnorePointer(
                    ignoring: !sundayState.visible,
                    child: EliteRitualButton(
                      time: "",
                      label: "Sunday Setup",
                      isSunday: true,
                      isDisabled: !sundayState.enabled,
                      onTap: () => onRitualTap?.call("sunday_setup"),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
