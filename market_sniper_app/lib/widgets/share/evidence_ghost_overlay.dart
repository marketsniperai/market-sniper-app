import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class EvidenceGhostOverlay extends StatelessWidget {
  final bool isElite;

  const EvidenceGhostOverlay({super.key, required this.isElite});

  @override
  Widget build(BuildContext context) {
    if (!isElite) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface1.withValues(alpha: 0.1),
              AppColors.surface1.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Center(
          child: Transform.rotate(
            angle: -0.2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textDisabled.withValues(alpha: 0.1), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "EVIDENCE-BACKED SNAPSHOT",
                style: GoogleFonts.robotoMono(
                  color: AppColors.textDisabled.withValues(alpha: 0.15),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
