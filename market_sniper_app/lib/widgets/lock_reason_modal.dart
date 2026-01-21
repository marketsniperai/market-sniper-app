import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/war_room_snapshot.dart'; // Canonical Model

/// Canonical method to show Lock Reason.
/// Ensures proper safe area and layout compliance.
Future<void> showLockReasonModal(
  BuildContext context, 
  LockReasonSnapshot snapshot,
  {String? titleOverride}
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => LockReasonModalContent(
      snapshot: snapshot, 
      titleOverride: titleOverride
    ),
  );
}

class LockReasonModalContent extends StatelessWidget {
  final LockReasonSnapshot snapshot;
  final String? titleOverride;

  const LockReasonModalContent({
    super.key, 
    required this.snapshot,
    this.titleOverride,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 16;
    final isLocked = snapshot.lockState.toUpperCase() == 'LOCKED';
    final stateColor = isLocked ? AppColors.stateLocked : AppColors.stateStale;
    final title = titleOverride ?? (isLocked ? "SYSTEM LOCKED" : "DATA STALE");

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Header ---
                Icon(
                  isLocked ? Icons.lock_outline : Icons.warning_amber_rounded,
                  size: 48,
                  color: stateColor,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.headline(context).copyWith(
                    color: stateColor,
                    fontSize: 24,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // --- Details Card ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow(context, "MODULE", snapshot.module),
                      const SizedBox(height: 12),
                      _buildRow(context, "CODE", snapshot.reasonCode),
                      const SizedBox(height: 12),
                      _buildRow(context, "REASON", snapshot.description, multiline: true),
                      const SizedBox(height: 12),
                      _buildRow(context, "TIMESTAMP", snapshot.timestamp),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // --- Guidance ---
                Text(
                  "OPERATIONAL GUIDANCE",
                  style: AppTypography.label(context).copyWith(color: AppColors.textDisabled),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isLocked 
                      ? "System protections active. Resolve root cause in War Room."
                      : "Data is stale. Refresh pipeline or check connection.",
                  style: AppTypography.body(context),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // --- Action ---
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface2,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("ACKNOWLEDGE"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value, {bool multiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(
            fontSize: 10, 
            color: AppColors.textDisabled, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          )
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.label(context).copyWith(
            color: AppColors.textPrimary, 
            fontSize: 14,
          ),
          maxLines: multiline ? 5 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
