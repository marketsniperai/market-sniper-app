import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../logic/tone.dart'; // Polish
import 'premium_screen.dart';

class RitualPreviewScreen extends StatelessWidget {
  final String title;
  final String description;

  final VoidCallback? onBack; // Shell Compliance
  final Function(Widget)? onNavigate; // Shell Compliance

  const RitualPreviewScreen({
    super.key,
    required this.title,
    required this.description,
    this.onBack,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeepVoid,
      child: Stack(
        children: [
          // Back Button
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () {
                if (onBack != null) {
                  onBack!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: 60, color: AppColors.neonCyan),
                const SizedBox(height: 32),
                Text(
                  "ELITE RITUAL",
                  style: GoogleFonts.jetBrainsMono(
                      color: AppColors.neonCyan,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  Tone.of(
                      human:
                          "This ritual provides institutional context for the session. Unlock it to align your execution.",
                      machine:
                          "Ritual locked. Institutional context required for execution alignment."),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.5),
                ),
                const SizedBox(height: 48),

                // Primary Action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (onNavigate != null) {
                        onNavigate!(PremiumScreen(
                            onBack: () => onNavigate!(RitualPreviewScreen(
                                title: title,
                                description: description,
                                onBack: onBack,
                                onNavigate: onNavigate))));
                      } else {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PremiumScreen()));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      foregroundColor: AppColors.bgDeepVoid,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("Unlock Premium Protocol",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                // Secondary
                TextButton(
                  onPressed: () {
                    if (onBack != null) {
                      onBack!();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Not Now",
                      style: GoogleFonts.inter(color: AppColors.textDisabled)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
