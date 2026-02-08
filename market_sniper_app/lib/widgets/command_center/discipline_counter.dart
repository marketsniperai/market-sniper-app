import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/command_center/command_center_tier.dart';

class DisciplineCounter extends StatelessWidget {
  final CommandCenterTier tier;
  final int count; // Free: taps remaining; Plus: days remaining
  final bool isUnlocked;
  final VoidCallback onTap;

  const DisciplineCounter({
    super.key,
    required this.tier,
    required this.count,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tier == CommandCenterTier.elite) return const SizedBox.shrink();

    // Plus: Show Days Remaining
    if (tier == CommandCenterTier.plus) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.ccSurfaceHigh,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.ccBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 10, color: AppColors.ccTextMono),
            const SizedBox(width: 4),
            Text(
              "$count",
              style: AppTypography.monoLabel(context),
            ),
          ],
        ),
      );
    }

    // Free: Show Taps or Unlocked State
    if (tier == CommandCenterTier.free) {
      if (isUnlocked) {
        // Door is open (but content frosted)
        return Text(
          "OPEN", // Minimal indicator
          style: AppTypography.monoTiny(context).copyWith(color: AppColors.textDisabled),
        );
      }
      
      // Locked: Show Tap Counter (Button-like)
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 20, 
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.ccBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.stateLocked),
            boxShadow: [
              BoxShadow(
                  color: AppColors.stateLocked.withValues(alpha: 0.2),
                  blurRadius: 4,
                  spreadRadius: 1)
            ],
          ),
          child: Text(
            "$count",
            style: AppTypography.monoTiny(context).copyWith(
              color: AppColors.stateLocked,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
