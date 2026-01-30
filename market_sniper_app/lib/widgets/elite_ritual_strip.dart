import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'elite_ritual_button.dart';

class EliteRitualStrip extends StatelessWidget {
  final Function(String)? onRitualTap;

  const EliteRitualStrip({super.key, this.onRitualTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // Compact height (reduced from 70)
      width: double.infinity,
      decoration: BoxDecoration(
        // Glass / Frosted semi-transparent - Inherited from parent?
        // Or specific strip glass. Let's keep it subtle interactions.
        color: AppColors.surface1.withValues(alpha: 0.2), 
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Tighter padding
        children: [
          SizedBox(
            width: 104,
            child: EliteRitualButton(
              time: "09:20 AM",
              label: "Morning Briefing",
              isDisabled: false, // Enable for testing logic
              onTap: () => onRitualTap?.call("morning_briefing"),
            ),
          ),
          SizedBox(
            width: 104,
            child: EliteRitualButton(
              time: "12:30 PM",
              label: "Mid-Day Report",
              isDisabled: true,
              onTap: () => onRitualTap?.call("mid_day_report"),
            ),
          ),
          SizedBox(
            width: 104,
            child: EliteRitualButton(
              time: "04:05 PM",
              label: "Market Resumed",
              isDisabled: true,
              onTap: () => onRitualTap?.call("market_resumed"),
            ),
          ),
          SizedBox(
            width: 104,
            child: EliteRitualButton(
              time: "04:10 PM",
              label: "How I Did Today",
              isDisabled: true,
              onTap: () => onRitualTap?.call("how_i_did_today"),
            ),
          ),
          SizedBox(
            width: 104,
            child: EliteRitualButton(
              time: "04:15 PM",
              label: "How You Did Today",
              isDisabled: true,
              onTap: () => onRitualTap?.call("how_you_did_today"),
            ),
          ),
          SizedBox(
            width: 104,
            child: EliteRitualButton(
              time: "",
              label: "Sunday Setup",
              isSunday: true,
              isDisabled: false, // Always visible per prompt
              onTap: () => onRitualTap?.call("sunday_setup"),
            ),
          ),
        ],
      ),
    );
  }
}
