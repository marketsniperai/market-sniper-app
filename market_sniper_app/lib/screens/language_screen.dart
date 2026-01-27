import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../state/locale_provider.dart';
import 'package:market_sniper_app/widgets/atoms/neon_outline_card.dart';

class LanguageScreen extends StatelessWidget {
  final VoidCallback? onBack; // Shell Compliance

  const LanguageScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    // Body-only layout (No Scaffold)
    return Container(
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          // Custom Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CloseButton(color: Colors.transparent), // Balancer
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          size: 20, color: AppColors.textPrimary),
                      onPressed: () {
                        if (onBack != null) {
                          onBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
                Text("LANGUAGE", style: AppTypography.title(context)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Consumer<LocaleProvider>(
                builder: (context, provider, child) {
                  final currentCode = provider.locale.languageCode;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SELECT PREFERENCE",
                        style: GoogleFonts.inter(
                          color: AppColors.textDisabled,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLanguageOption(
                          context, "English", "en", currentCode, provider),
                      const SizedBox(height: 12),
                      _buildLanguageOption(
                          context, "Español", "es", currentCode, provider),
                      const SizedBox(height: 12),
                      _buildLanguageOption(
                          context, "Português", "pt", currentCode, provider),
                      const SizedBox(height: 12),
                      _buildLanguageOption(
                          context, "Hindi (हिंदी)", "hi", currentCode, provider),
                      const SizedBox(height: 12),
                      _buildLanguageOption(
                          context, "中文 (Chinese)", "zh", currentCode, provider),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String label, String code,
      String currentCode, LocaleProvider provider) {
    final bool isActive = currentCode == code;
    return InkWell(
      onTap: () {
        if (!isActive) {
          provider.setLocale(Locale(code));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.neonCyan.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.neonCyan.withValues(alpha: 0.5)
                : AppColors.borderSubtle,
            width: 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? AppColors.neonCyan : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isActive)
              const Icon(Icons.check_circle,
                  color: AppColors.neonCyan, size: 20),
          ],
        ),
      ),
    );
  }
}
