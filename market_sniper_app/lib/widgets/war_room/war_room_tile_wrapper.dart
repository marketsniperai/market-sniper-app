import 'package:flutter/material.dart';
import 'package:market_sniper_app/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market_sniper_app/widgets/atoms/neon_outline_card.dart';

class WarRoomTileWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;
  final VoidCallback? onTap;

  const WarRoomTileWrapper({
    super.key,
    required this.title,
    required this.child,
    this.height = 140,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeonOutlineCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      // Keep surface1 background as per original design, handled by default in NeonOutlineCard or explicit
      backgroundColor: AppColors.surface1,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.grid_view,
                      size: 14,
                      color: AppColors.textSecondary), // Generic tile icon
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
