import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class EliteMentorBridgeButton extends StatelessWidget {
  final bool isLocked;
  final VoidCallback onTap;

  const EliteMentorBridgeButton({
    super.key,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Styling based on Lock State
    final Color borderColor = isLocked ? AppColors.stateLocked : AppColors.neonCyan;
    final Color textColor = isLocked ? AppColors.textDisabled : AppColors.neonCyan;
    final WidgetStateProperty<Color?> overlayColor = WidgetStateProperty.all(
        isLocked ? Colors.transparent : AppColors.neonCyan.withValues(alpha: 0.1)
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        overlayColor: overlayColor,
        borderRadius: BorderRadius.circular(8),
        splashColor: isLocked ? Colors.transparent : AppColors.neonCyan.withValues(alpha: 0.1),
        highlightColor: isLocked ? Colors.transparent : AppColors.neonCyan.withValues(alpha: 0.05),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLocked ? Icons.lock : Icons.auto_awesome,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Text(
                isLocked ? "ELITE MENTORSHIP LOCKED" : "EXPLAIN THIS DOSSIER",
                style: AppTypography.label(context).copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              if (!isLocked) ...[
                const SizedBox(width: 4),
                 // Little arrow or similar? Nah, clean is better.
              ]
            ],
          ),
        ),
      ),
    );
  }
}
