import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class ShareBoosterSheet extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onUpgrade;
  final bool showUpgrade;

  const ShareBoosterSheet({
    super.key,
    required this.onSave,
    required this.onShare,
    required this.onUpgrade,
    this.showUpgrade = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: AppColors.neonCyan, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.neonCyan, size: 24),
              const SizedBox(width: 12),
              Text("Share Ready", style: AppTypography.headline(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Want stronger captions or deeper context framing?",
            style: AppTypography.body(context)
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSave,
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderSubtle)),
                  child:
                      Text("Save Image", style: AppTypography.label(context)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onShare,
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderSubtle)),
                  child: Text("Share", style: AppTypography.label(context)),
                ),
              ),
            ],
          ),
          if (showUpgrade) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface2),
                child: Text("Unlock Elite",
                    style: AppTypography.label(context)
                        .copyWith(color: AppColors.stateStale)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
