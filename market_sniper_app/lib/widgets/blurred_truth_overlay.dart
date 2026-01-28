import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'elite_mentor_bridge_button.dart'; // Reuse the button style or similar logic if needed, but we'll built custom here.

/// D47.HF30: A glassmorphic overlay for gating forward-looking intelligence.
class BlurredTruthOverlay extends StatelessWidget {
  final VoidCallback onUnlockTap;
  final String ctaLabel;
  final double sigma;

  const BlurredTruthOverlay({
    super.key,
    required this.onUnlockTap,
    this.ctaLabel = "UNLOCK FUTURE",
    this.sigma = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect( // Ensure blur doesn't bleed
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          color: AppColors.bgPrimary.withValues(alpha: 0.3), // Darken slightly
          child: Center(
            child: GestureDetector(
               onTap: onUnlockTap,
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 decoration: BoxDecoration(
                   color: AppColors.stateLocked.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(20),
                   border: Border.all(color: AppColors.stateLocked.withValues(alpha: 0.5)),
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Icon(Icons.lock, size: 14, color: AppColors.stateLocked),
                     const SizedBox(width: 8),
                     Text(
                       ctaLabel,
                       style: AppTypography.label(context).copyWith(
                         color: AppColors.stateLocked,
                         fontWeight: FontWeight.bold,
                         letterSpacing: 1.0,
                       ),
                     ),
                   ],
                 ),
               ),
            ),
          ),
        ),
      ),
    );
  }
}
