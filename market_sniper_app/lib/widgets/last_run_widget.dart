import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/last_run_snapshot.dart';

class LastRunWidget extends StatelessWidget {
  final LastRunSnapshot lastRun;
  final bool isFounder;

  const LastRunWidget({
    super.key, 
    required this.lastRun,
    this.isFounder = false,
  });

  Color get _resultColor {
    switch (lastRun.result) {
      case LastRunResult.ok:
        return AppColors.stateLive;
      case LastRunResult.partial:
        return AppColors.stateStale;
      case LastRunResult.misfire:
      case LastRunResult.failed:
        return AppColors.stateLocked;
      case LastRunResult.unknown:
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
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "LAST RUN",
                style: GoogleFonts.inter(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (lastRun.type != LastRunType.unknown)
                Row(
                  children: [
                    Text(
                      lastRun.type.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildResultChip(),
                  ],
                )
              else
                 Text(
                  "NO DATA",
                  style: GoogleFonts.inter(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          
          if (lastRun.ageSeconds >= 0) ...[
            const SizedBox(height: 8),
            // Age Line
            Row(
              children: [
                Text(
                  "AGE: ",
                  style: GoogleFonts.inter(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "${lastRun.ageSeconds}s ago",
                  style: GoogleFonts.robotoMono(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          
          if (isFounder) ...[
             const SizedBox(height: 8),
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(4),
               color: AppColors.bgPrimary.withValues(alpha: 0.5),
               child: Text(
                 "RUN ID: ${lastRun.runId} | TS: ${lastRun.timestamp ?? 'N/A'}",
                 style: GoogleFonts.robotoMono(
                   color: AppColors.accentCyanDim,
                   fontSize: 9,
                 ),
               ),
             ),
          ]
        ],
      ),
    );
  }

  Widget _buildResultChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Slimmer
      decoration: BoxDecoration(
        color: _resultColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _resultColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        lastRun.result.name.toUpperCase(),
        style: GoogleFonts.inter(
          color: _resultColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
