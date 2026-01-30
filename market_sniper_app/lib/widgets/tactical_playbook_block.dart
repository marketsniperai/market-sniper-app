import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'blurred_truth_overlay.dart'; // D47.HF30

class TacticalPlaybookBlock extends StatelessWidget {
  final List<String> watchItems;
  final List<String> invalidateItems;
  final bool isCalibrationMode;
  final bool isBlurred; // D47.HF30

  const TacticalPlaybookBlock({
    super.key,
    required this.watchItems,
    required this.invalidateItems,
    this.isCalibrationMode = false,
    this.isBlurred = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2, // Slightly darker distinctive block
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TACTICAL PLAYBOOK",
                style: AppTypography.label(context).copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              if (isCalibrationMode)
                 Text(
                   "CALIBRATION WINDOW",
                   style: AppTypography.caption(context).copyWith(
                     color: AppColors.neonCyan,
                     fontWeight: FontWeight.bold,
                     fontSize: 9
                   ),
                 ),
            ],
          ),
          const SizedBox(height: 12),
          

          // GATED CONTENT AREA
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // WATCH SECTION
                  _buildSectionHeader(context, "WATCH FOR", AppColors.marketBull),
                  const SizedBox(height: 6),
                  ...watchItems.map((item) => _buildBullet(context, item)),
                  
                  const SizedBox(height: 12),
                  
                  // INVALIDATE SECTION
                  _buildSectionHeader(context, "INVALIDATED IF", AppColors.marketBear),
                  const SizedBox(height: 6),
                  ...invalidateItems.map((item) => _buildBullet(context, item)),
                ],
              ),
              
              if (isBlurred)
                 Positioned.fill(
                   child: BlurredTruthOverlay(
                      onUnlockTap: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Upgrade to Elite to unlock tactical specifics."))
                         );
                      },
                      ctaLabel: "UNLOCK PLAN",
                      sigma: 5.0,
                   ),
                 ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4, 
          height: 12, 
          color: color,
          margin: const EdgeInsets.only(right: 6),
        ),
        Text(
          title,
          style: AppTypography.label(context).copyWith(
             color: color,
             fontWeight: FontWeight.bold,
             fontSize: 11
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5.0, right: 6.0),
            child: Container(
              width: 3, 
              height: 3, 
              decoration: const BoxDecoration(
                color: AppColors.textDisabled,
                shape: BoxShape.circle
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(context).copyWith(
                fontSize: 12, 
                color: AppColors.textSecondary,
                height: 1.3
              ),
            ),
          ),
        ],
      ),
    );
  }
}
