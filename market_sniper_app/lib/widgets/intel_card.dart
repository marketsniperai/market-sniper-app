import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class IntelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> lines;
  final Color accentColor; // Green, Amber, Red, Gray
  final String tooltip;
  final bool isCalibrating;

  const IntelCard({
    super.key,
    required this.title,
    required this.icon,
    required this.lines,
    required this.accentColor,
    required this.tooltip,
    this.isCalibrating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface1, // Slightly lighter than bg
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Accent Bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                         Icon(icon, size: 14, color: AppColors.textSecondary),
                         const SizedBox(width: 8),
                         Expanded(
                           child: Text(
                             title.toUpperCase(),
                             style: AppTypography.label(context).copyWith(
                               color: AppColors.textSecondary,
                               letterSpacing: 1.0,
                               fontSize: 10
                             ),
                           ),
                         ),
                         // Tooltip / Help
                         Tooltip(
                           message: tooltip,
                           textStyle: AppTypography.caption(context).copyWith(color: AppColors.textPrimary),
                           decoration: BoxDecoration(
                             color: AppColors.surface2,
                             borderRadius: BorderRadius.circular(4),
                             border: Border.all(color: AppColors.borderSubtle),
                           ),
                           child: Icon(Icons.help_outline, size: 12, color: AppColors.textDisabled),
                         )
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Body
                    if (isCalibrating)
                      Text(
                        "CALIBRATING...",
                        style: AppTypography.caption(context).copyWith(
                          color: AppColors.neonCyan,
                          fontStyle: FontStyle.italic
                        ),
                      )
                    else
                      ...lines.map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Text(
                          line,
                          style: AppTypography.body(context).copyWith(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
