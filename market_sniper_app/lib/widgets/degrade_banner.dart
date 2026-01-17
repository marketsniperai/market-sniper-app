import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../logic/dashboard_degrade_policy.dart';

class DegradeBanner extends StatelessWidget {
  final DegradeContext degradeContext;
  final bool isFounder;

  const DegradeBanner({
    super.key,
    required this.degradeContext,
    this.isFounder = false,
  });

  @override
  Widget build(BuildContext context) {
    if (degradeContext.state == DegradeState.ok) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color borderColor;
    Color textColor;
    String label;

    switch (degradeContext.state) {
      case DegradeState.unavailable:
        bgColor = AppColors.stateLocked.withValues(alpha: 0.1);
        borderColor = AppColors.stateLocked.withValues(alpha: 0.4);
        textColor = AppColors.stateLocked;
        label = "DATA UNAVAILABLE";
        break;
      case DegradeState.stale:
        bgColor = AppColors.stateStale.withValues(alpha: 0.1);
        borderColor = AppColors.stateStale.withValues(alpha: 0.4);
        textColor = AppColors.stateStale;
        label = "STALE DATA";
        break;
      case DegradeState.partial:
        bgColor = AppColors.accentCyanDim.withValues(alpha: 0.1);
        borderColor = AppColors.accentCyanDim.withValues(alpha: 0.4);
        textColor = AppColors.accentCyanDim;
        label = "PARTIAL DATA";
        break;
      case DegradeState.ok:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (isFounder)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 22),
              child: Text(
                "REASON: ${degradeContext.reasonCode} ${degradeContext.missingFields.isNotEmpty ? '| MISSING: ${degradeContext.missingFields}' : ''}",
                style: GoogleFonts.robotoMono(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 9,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
