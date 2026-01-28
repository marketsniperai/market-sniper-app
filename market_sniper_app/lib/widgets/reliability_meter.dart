import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ReliabilityMeter extends StatelessWidget {
  final String state; // HIGH, MED, LOW, CALIBRATING
  final int? sampleSize;
  final String driftState; // LOW, MED, HIGH, N/A
  final int activeInputs;
  final int totalInputs;

  const ReliabilityMeter({
    super.key,
    required this.state,
    this.sampleSize,
    this.driftState = "N/A",
    required this.activeInputs,
    required this.totalInputs,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine Main Color
    Color mainColor;
    switch (state) {
      case "HIGH":
        mainColor = AppColors.stateLive;
        break;
      case "MED":
        mainColor = AppColors.stateStale;
        break;
      case "LOW":
        mainColor = AppColors.marketBear;
        break;
      case "CALIBRATING":
      default:
        mainColor = AppColors.neonCyan;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("RELIABILITY",
                  style: AppTypography.label(context)
                      .copyWith(color: AppColors.textDisabled, fontSize: 10)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: mainColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: mainColor),
                ),
                child: Text(
                  state,
                  style: AppTypography.label(context).copyWith(
                      color: mainColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildDetailChip(
                  context,
                  "SAMPLES",
                   sampleSize != null ? "N=$sampleSize" : "CALIBRATING",
                   sampleSize != null ? AppColors.textSecondary : AppColors.neonCyan
              ),
              _buildDetailChip(
                  context,
                  "DRIFT",
                  driftState,
                  driftState == "HIGH" ? AppColors.marketBear : AppColors.textSecondary
              ),
               _buildDetailChip(
                  context,
                  "INPUTS",
                  "$activeInputs/$totalInputs LIVE",
                   activeInputs < totalInputs ? AppColors.stateStale : AppColors.stateLive
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(BuildContext context, String label, String value, Color valueColor) {
    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
       decoration: BoxDecoration(
         color: AppColors.surface1,
         borderRadius: BorderRadius.circular(4),
         border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Text("$label: ", style: AppTypography.label(context).copyWith(fontSize: 9, color: AppColors.textDisabled)),
           Text(value, style: AppTypography.label(context).copyWith(fontSize: 9, color: valueColor, fontWeight: FontWeight.bold)),
         ],
       ),
    );
  }
}
