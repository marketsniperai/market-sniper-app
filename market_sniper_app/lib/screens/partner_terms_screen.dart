import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PartnerTermsScreen extends StatelessWidget {
  final VoidCallback? onBack; // Shell Compliance
  const PartnerTermsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          // Custom Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
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
                Expanded(
                  child: Text(
                    "Partner Terms & Conditions",
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Partner Program Disclosure",
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  _buildTermItem("1. Authorization",
                      "You are an authorized beta partner."),
                  _buildTermItem("2. No Spam",
                      "Unsolicited marketing triggers prompt termination."),
                  _buildTermItem("3. Disclosure",
                      "You must clearly disclose your relationship with MarketSniper AI."),
                  _buildTermItem("4. Payouts (Inactive)",
                      "Payout mechanism is currently in staging. No funds will be disbursed during this beta phase."),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.marketBear.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "NOTE: This is a stub legal agreement for I8.0 Launch Readiness. Use for layout verification only.",
                      style: GoogleFonts.robotoMono(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(body,
              style: GoogleFonts.inter(
                  color: AppColors.textDisabled, height: 1.4)),
        ],
      ),
    );
  }
}
