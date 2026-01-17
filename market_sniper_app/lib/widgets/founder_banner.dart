import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FounderBanner extends StatelessWidget {
  const FounderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.accentCyanDim.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.accentCyanDim.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          "FOUNDER VIEW — SYSTEM VISIBILITY ENABLED",
          style: GoogleFonts.inter(
            color: AppColors.accentCyan,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
