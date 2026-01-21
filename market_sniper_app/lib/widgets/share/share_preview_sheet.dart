import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../logic/share/caption_service.dart';
import '../../logic/share/share_composer.dart';
import '../../logic/share/share_exporter.dart';
import '../../logic/premium_status_resolver.dart';
import '../../models/premium/premium_matrix_model.dart';
import 'package:intl/intl.dart';

class SharePreviewSheet extends StatefulWidget {
  final String title;
  final List<String> bullets;

  const SharePreviewSheet({super.key, required this.title, required this.bullets});

  @override
  State<SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<SharePreviewSheet> {
  CaptionPreset _selectedPreset = CaptionPreset.institutional;
  final GlobalKey _repaintKey = GlobalKey();
  
  @override
  Widget build(BuildContext context) {
    final currentTier = PremiumStatusResolver.currentTier;
    final isFounder = currentTier == PremiumTier.founder;
    final isElite = currentTier == PremiumTier.elite || isFounder;
    final tierLabel = currentTier.name.toUpperCase();

    // Generate Caption
    final caption = CaptionService.generate(_selectedPreset, ticker: widget.title);

    // Build the Card Widget for Preview
    final shareCard = ShareComposer.buildShareCard(
       context,
       title: widget.title,
       timestamp: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
       bullets: widget.bullets,
       mode: tierLabel,
       shareId: "SH-${DateTime.now().millisecond}", // Mock ID
       isFounder: isFounder,
       isElite: isElite,
    );

    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text("SHARE PREVIEW", style: AppTypography.title(context)),
               IconButton(
                 icon: const Icon(Icons.close, color: AppColors.textDisabled),
                 onPressed: () => Navigator.pop(context),
               ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Preview Area
          Expanded( // Scrollable preview
            child: SingleChildScrollView(
              child: Column(
                children: [
                   RepaintBoundary(
                      key: _repaintKey,
                      child: shareCard,
                   ),
                   const SizedBox(height: 24),
                   
                   // Caption Selector
                   Text("CAPTION STYLE", style: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 10, letterSpacing: 1.0)),
                   const SizedBox(height: 8),
                   SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     child: Row(
                       children: CaptionPreset.values.map((preset) {
                          final isSelected = _selectedPreset == preset;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(preset.name.toUpperCase(), style: GoogleFonts.robotoMono(fontSize: 10)),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedPreset = preset),
                              selectedColor: AppColors.accentCyan.withValues(alpha: 0.2),
                              backgroundColor: AppColors.surface1,
                              labelStyle: TextStyle(color: isSelected ? AppColors.accentCyan : AppColors.textDisabled),
                            ),
                          );
                       }).toList(),
                     ),
                   ),
                   const SizedBox(height: 16),
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                     ),
                     child: Text(
                        caption,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                     ),
                   ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          ElevatedButton.icon(
             icon: const Icon(Icons.share, size: 18),
             label: const Text("EXPORT & SHARE"),
             style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: AppColors.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
             ),
             onPressed: () async {
                 // 1. Capture
                 final path = await ShareExporter.captureAndSave(_repaintKey, "share_export.png");
                 if (path != null) {
                    if (!context.mounted) return;
                    // 2. Share
                    await ShareExporter.shareFile(context, path, text: caption);
                    if (context.mounted) Navigator.pop(context);
                 }
             },
          ),
        ],
      ),
    );
  }
}
