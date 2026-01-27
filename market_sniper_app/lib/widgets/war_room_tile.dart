import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../config/app_config.dart';

enum WarRoomTileStatus {
  nominal,
  degraded,
  incident, // Misfire or Locked
  unavailable,
  loading,
}

class WarRoomTile extends StatelessWidget {
  final String title;
  final WarRoomTileStatus status;
  final List<String> subtitle;
  final String? debugInfo;
  final VoidCallback? onTap;
  final Widget? customBody;

  const WarRoomTile({
    super.key,
    required this.title,
    required this.status,
    required this.subtitle,
    this.debugInfo,
    this.onTap,
    this.customBody,
  });

  Color get _statusColor {
    switch (status) {
      case WarRoomTileStatus.nominal:
        return AppColors.marketBull; // Green or Cyan
      case WarRoomTileStatus.degraded:
        return AppColors.stateStale; // Orange
      case WarRoomTileStatus.incident:
        return AppColors.marketBear; // Red
      case WarRoomTileStatus.unavailable:
        return AppColors.textDisabled;
      case WarRoomTileStatus.loading:
        return AppColors.textSecondary;
    }
  }

  Color get _borderColor {
    if (status == WarRoomTileStatus.loading) return AppColors.borderSubtle;
    if (status == WarRoomTileStatus.unavailable) return AppColors.borderSubtle;
    return _statusColor.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.label(context).copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
                _buildStatusIndicator(),
              ],
            ),

            // Content
            Expanded(
              child: customBody ??
                  Center(
                    child: _buildBody(context),
                  ),
            ),

            // Footer (Debug)
            if (AppConfig.isFounderBuild && debugInfo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  debugInfo!,
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontFamily: 'monospace',
                    fontSize: 8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (status == WarRoomTileStatus.loading) {
      return const SizedBox(
        width: 8,
        height: 8,
        child: CircularProgressIndicator(strokeWidth: 1),
      );
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _statusColor,
        shape: BoxShape.circle,
        boxShadow: [
          if (status == WarRoomTileStatus.nominal ||
              status == WarRoomTileStatus.incident)
            BoxShadow(
                color: _statusColor.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1)
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (status == WarRoomTileStatus.loading) {
      return const Text("...");
    }
    if (status == WarRoomTileStatus.unavailable) {
      return Text(
        "UNAVAILABLE",
        style: AppTypography.body(context).copyWith(
          color: AppColors.textDisabled,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    if (subtitle.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: subtitle
          .map((line) => Text(
                line,
                textAlign: TextAlign.center,
                style: AppTypography.headline(context).copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ))
          .toList(),
    );
  }
}
