import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../config/app_config.dart';
import 'war_room/war_room_tile_meta.dart';

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
  final bool compact;
  final WarRoomTileMeta? meta;
  final bool showSourceOverlay;

  const WarRoomTile({
    super.key,
    required this.title,
    required this.status,
    required this.subtitle,
    this.debugInfo,
    this.onTap,
    this.customBody,
    this.compact = false,
    this.meta,
    this.showSourceOverlay = false,
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
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12, vertical: compact ? 2 : 12), // D54.1: Tighter vertical
            decoration: BoxDecoration(
              color: AppColors.surface1,
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(compact ? 6 : 12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // D54.0: Prevent unbounded height crash
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
                      maxLines: 1, // D54.1: Safety
                      overflow: TextOverflow.ellipsis,
                    ),
                    _buildStatusIndicator(),
                  ],
                ),

                // Content
                Flexible(
                  fit: FlexFit.loose,
                  child: customBody ??
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _buildBody(context),
                        ),
                      ),
                ),

                // Footer (Debug)
                if (AppConfig.isFounderBuild && debugInfo != null && !showSourceOverlay)
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
          if (showSourceOverlay && meta != null) _buildSourceOverlay(),
        ],
      ),
    );
  }

  Widget _buildSourceOverlay() {
    // Traffic light discipline:
    // REAL = subtle cyan/gray
    // N/A = gray (same as real but contextually dimmed usually, here just standard)
    // SIMULATED = amber label
    Color labelColor = AppColors.textSecondary;
    if (meta!.origin == WarRoomDataOrigin.simulated) {
      labelColor = AppColors.stateStale; // Amber
    } else if (meta!.origin == WarRoomDataOrigin.real) {
      labelColor = Colors.cyan.withAlpha(200);
    }

    // Determine effective status based on UI state vs Meta intent
    // (Visual helper only)

    return Positioned(
      top: 2,
      left: 2,
      right: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(220),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              meta!.endpoint,
              style: GoogleFonts.robotoMono(
                fontSize: 8,
                color: labelColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "${meta!.fieldPath} [${meta!.origin.name.toUpperCase()}]",
              style: GoogleFonts.robotoMono(
                fontSize: 7,
                color: Colors.white38,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                  fontSize: compact ? 10 : 14,
                  color: AppColors.textPrimary,
                ),
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis, // D54.1: Safety
              ))
          .toList(),
    );
  }
}
