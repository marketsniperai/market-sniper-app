import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/system_health_snapshot.dart';
import 'package:google_fonts/google_fonts.dart';

class OSHealthWidget extends StatelessWidget {
  final SystemHealthSnapshot health;
  final bool isFounder;

  const OSHealthWidget({
    super.key,
    required this.health,
    this.isFounder = false,
  });

  Color get _statusColor {
    switch (health.status) {
      case HealthStatus.nominal:
        return AppColors.stateLive;
      case HealthStatus.degraded:
        return AppColors.stateStale;
      case HealthStatus.misfire:
      case HealthStatus.locked:
        return AppColors.stateLocked;
      case HealthStatus.unknown:
        return AppColors.textDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "OS HEALTH",
                style: GoogleFonts.inter(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 8),

          // Source + Age Line (Minimal)
          Row(
            children: [
              Text(
                "SOURCE: ",
                style: GoogleFonts.inter(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                health.source.name.toUpperCase(),
                style: GoogleFonts.robotoMono(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (health.ageSeconds >= 0) ...[
                const SizedBox(width: 12),
                Text(
                  "AGE: ",
                  style: GoogleFonts.inter(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "${health.ageSeconds}s",
                  style: GoogleFonts.robotoMono(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),

          if (isFounder) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              color: AppColors.bgPrimary.withValues(alpha: 0.5),
              child: Text(
                "DEBUG: ${health.message} | TS: ${health.rawTimestamp ?? 'N/A'}",
                style: GoogleFonts.robotoMono(
                  color: AppColors.accentCyanDim,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        health.status.name.toUpperCase(),
        style: GoogleFonts.inter(
          color: _statusColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
