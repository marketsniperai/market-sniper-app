import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/war_room_snapshot.dart';
import '../../../models/system_health_snapshot.dart';
import '../../../config/app_config.dart';
import '../../command_center/discipline_counter.dart';

import '../../../models/command_center/command_center_tier.dart';
import 'package:intl/intl.dart';

class GlobalCommandBar extends StatelessWidget {
  final WarRoomSnapshot snapshot;
  final VoidCallback onRefresh;
  final bool loading;
  final bool silentRefreshing;
  final DateTime? lastRefreshTime;
  final bool showSources;
  final VoidCallback? onToggleSources;
  
  // D61.2: Discipline Inputs
  final CommandCenterTier? disciplineTier;
  final int? disciplineCount;
  final bool? disciplineUnlocked;
  final VoidCallback? onDisciplineTap;

  const GlobalCommandBar({
    super.key,
    required this.snapshot,
    required this.onRefresh,
    required this.loading,
    required this.silentRefreshing,
    this.lastRefreshTime,
    this.showSources = false,
    this.onToggleSources,
    this.disciplineTier,
    this.disciplineCount,
    this.disciplineUnlocked,
    this.onDisciplineTap,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("WARROOM_ZONE Z1 build");
    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Title & Founder Badge
          Row(
            children: [
              Text(
                "WAR ROOM",
                style: AppTypography.headline(context).copyWith(
                  letterSpacing: 2.0,
                  color: AppColors.textPrimary,
                ),
              ),
              if (AppConfig.isFounderBuild) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withOpacity(0.1),
                    border: Border.all(color: AppColors.neonCyan, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "FDR",
                    style: GoogleFonts.robotoMono(
                      color: AppColors.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // D53.6B.1: No-Blank Proof Marker
                const SizedBox(width: 8),
                Text(
                  "ZONES: 4 | STATE: ${loading ? 'LOAD' : 'OK'}",
                  style: GoogleFonts.robotoMono(
                    fontSize: 9, 
                    color: AppColors.textPrimary.withOpacity(0.24),
                    fontWeight: FontWeight.w500
                  ),
                ),
                // D53.6C: Layout Proof Chip
                const SizedBox(width: 8),
                Builder(builder: (context) {
                   final w = MediaQuery.of(context).size.width;
                   int c2 = w < 520 ? 2 : w < 820 ? 3 : w < 1200 ? 4 : 6;
                   int c3 = w < 520 ? 2 : w < 820 ? 2 : w < 1200 ? 4 : 4;
                   return Container(
                     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                     decoration: BoxDecoration(
                       color: AppColors.neonCyan.withOpacity(0.2),
                       borderRadius: BorderRadius.circular(2),
                       border: Border.all(color: AppColors.neonCyan.withOpacity(0.5), width: 0.5),
                     ),
                     child: Text(
                        "W:${w.toInt()} C2:$c2 C3:$c3",
                        style: GoogleFonts.robotoMono(fontSize: 9, color: AppColors.neonCyan),
                     ),
                   );
                }),
                // D61.2D Web Truth Stamp
                if (kIsWeb && kDebugMode) ...[
                  const SizedBox(width: 8),
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                     decoration: BoxDecoration(
                       color: AppColors.neonCyan.withValues(alpha: 0.2),
                       border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.5)),
                       borderRadius: BorderRadius.circular(2),
                     ),
                     child: Text(
                       "api:${AppConfig.apiBaseUrl.replaceAll('http://', '').replaceAll('https://', '')}",
                       style: GoogleFonts.robotoMono(fontSize: 8, color: AppColors.neonCyan),
                     ),
                  ),
                ],
              ],
            ],
          ),

          // D61.2: Discipline Counter (Near Logo/Title)
          if (disciplineTier != null) ...[
             const SizedBox(width: 12),
             DisciplineCounter(
               tier: disciplineTier!,
               count: disciplineCount ?? 0,
               isUnlocked: disciplineUnlocked ?? false,
               onTap: onDisciplineTap ?? () {},
             ),
          ],

          const Spacer(),

          // 2. Status Banner Logic (Condensed)
          _buildStatusIndicator(context),

          const SizedBox(width: 16),

          // 3. Last Refresh / Loading
          _buildRefreshStatus(context),

          // 4. SRC Toggle (Founder Only)
          if (AppConfig.isFounderBuild && onToggleSources != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onToggleSources,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: showSources ? AppColors.textPrimary.withOpacity(0.1) : AppColors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: showSources
                          ? AppColors.textSecondary
                          : Colors.transparent),
                ),
                child: Text(
                  "SRC",
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: showSources
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    // Priority 1: Locked
    if (snapshot.osHealth.status == HealthStatus.locked) {
      return _statusBadge(
          context, "LOCKED", AppColors.stateLocked, Icons.lock_outline);
    }

    // Priority 2: Degraded (Any Missing)
    bool autopilotMissing = !snapshot.autopilot.isAvailable;
    bool misfireMissing = !snapshot.misfire.isAvailable;
    bool housekeeperMissing = !snapshot.housekeeper.isAvailable;
    bool ironMissing = !snapshot.iron.isAvailable;

    if (autopilotMissing ||
        misfireMissing ||
        housekeeperMissing ||
        ironMissing) {
      return _statusBadge(
          context, "DEGRADED", AppColors.stateStale, Icons.warning_amber_rounded);
    }

    // Default: Healthy
    return _statusBadge(
        context, "SECURE", AppColors.stateLive, Icons.shield_outlined);
  }

  Widget _statusBadge(
      BuildContext context, String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.robotoMono(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshStatus(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.neonCyan,
        ),
      );
    }

    return Row(
      children: [
        if (silentRefreshing)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppColors.textDisabled)),
          ),
        if (lastRefreshTime != null)
          Text(
            DateFormat('HH:mm:ss').format(lastRefreshTime!.toLocal()),
            style: AppTypography.caption(context).copyWith(
              fontFamily: GoogleFonts.robotoMono().fontFamily,
              color: AppColors.textDisabled,
            ),
          ),
      ],
    );
  }
}
