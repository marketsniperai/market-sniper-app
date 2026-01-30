import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class EliteRitualButton extends StatelessWidget {
  final String time;
  final String label;
  final VoidCallback? onTap;
  final bool isSunday;
  final bool isDisabled;

  const EliteRitualButton({
    super.key,
    this.time = "",
    required this.label,
    this.onTap,
    this.isSunday = false,
    this.isDisabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on state
    final Color borderColor = isSunday
        ? AppColors.neonCyan.withValues(alpha: 0.5)
        : (isDisabled ? AppColors.borderSubtle : AppColors.neonCyan);
    
    final Color textColor = isSunday
        ? AppColors.neonCyan
        : (isDisabled ? AppColors.textDisabled : AppColors.textPrimary);
    
    final Color timeColor = isSunday
        ? AppColors.neonCyan.withValues(alpha: 0.8)
        : (isDisabled ? AppColors.textDisabled.withValues(alpha: 0.7) : AppColors.textSecondary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled && !isSunday ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // No fixed width, parent controls width via Expanded
          constraints: const BoxConstraints(minHeight: 44, maxHeight: 48), 
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), 
          decoration: BoxDecoration(
            // Glassmorphic feel
            color: AppColors.surface1.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (time.isNotEmpty)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    time,
                    maxLines: 1,
                    style: AppTypography.caption(context).copyWith(
                      color: timeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTypography.label(context).copyWith(
                    color: textColor,
                    fontSize: 10, // Slightly smaller base to fit "Morning Briefing"
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
