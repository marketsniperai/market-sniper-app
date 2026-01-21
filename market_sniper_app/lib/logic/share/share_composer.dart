import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'watermark_service.dart';
import '../../widgets/share/evidence_ghost_overlay.dart';

class ShareComposer {
  // Builds a Share Card Widget ready for RepaintBoundary
  static Widget buildShareCard(BuildContext context, {
    required String title,
    required String timestamp,
    required List<String> bullets,
    String mode = "PREVIEW",
    String? shareId,
    bool isFounder = false,
    bool isElite = false,
  }) {
    // 1. Base Card
    final card = Container(
       width: 400, // Fixed width for consistent generation
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(0), // Sharp for share image
          border: Border.all(color: AppColors.accentCyan, width: 2),
       ),
       child: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
             // Header
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text("MARKETSNIPER", style: AppTypography.label(context).copyWith(color: AppColors.accentCyan)),
                         Text("INTELLIGENCE SNAPSHOT", style: const TextStyle(color: AppColors.textDisabled, fontSize: 8, fontFamily: 'RobotoMono', letterSpacing: 1.5)),
                      ],
                   ),
                   // Optional Logo placeholder
                   const Icon(Icons.hub, color: AppColors.accentCyan, size: 24),
                ],
             ),
             const Divider(color: AppColors.borderSubtle, height: 32),
             
             // Content
             Text(title, style: AppTypography.headline(context).copyWith(fontSize: 24)),
             const SizedBox(height: 8),
             Text("AS OF: $timestamp", style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'RobotoMono', fontSize: 10)),
             const SizedBox(height: 24),
             
             ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const Text("• ", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(b, style: AppTypography.body(context).copyWith(fontSize: 14))),
                   ],
                ),
             )),
             
             const SizedBox(height: 48), // Space for watermark
         ],
       ),
    );

    // 2. Logic: Watermark + Ghost Overlay
    final withOverlay = Stack(
       children: [
          card,
          Positioned.fill(child: EvidenceGhostOverlay(isElite: isElite)),
       ],
    );

    // 3. Apply Watermark
    return Container(
       color: AppColors.surface1, // Background behind card if needed, or card IS bg
       child: WatermarkService.applyWatermark(
         context, 
         withOverlay, 
         tierLabel: mode, 
         shareId: shareId,
         isFounder: isFounder,
         isElite: isElite,
       ),
    );
  }
}
