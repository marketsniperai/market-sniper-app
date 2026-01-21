import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class WatermarkService {
  static const String _kSlogan = "Institutional Power... In Your Pocket.";
  static const String _kInstallHint = "Get the OS → MarketSniper AI";

  static Widget applyWatermark(BuildContext context, Widget content, {
    String tierLabel = "PREVIEW", 
    String? shareId,
    bool isFounder = false,
    bool isElite = false,
  }) {
    final bool showSlogan = isFounder || isElite;
    final bool showBrand = true; // Always show brand
    
    return Stack(
      children: [
        content,
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             mainAxisSize: MainAxisSize.min,
             children: [
               if (showSlogan)
                 Text(_kSlogan, 
                   style: const TextStyle(
                     color: AppColors.textSecondary,
                     fontSize: 10,
                     fontStyle: FontStyle.italic,
                     fontWeight: FontWeight.bold,
                     fontFamily: 'RobotoMono'
                   )
                 ),
               if (showBrand) ...[
                 const SizedBox(height: 2),
                 Text("MARKETSNIPER.AI | ${_formatTierLabel(tierLabel)}", 
                   style: const TextStyle(
                     color: AppColors.textDisabled,
                     fontSize: 8,
                     fontFamily: 'RobotoMono'
                   )
                 ),
               ],
               if (shareId != null) ...[
                  const SizedBox(height: 4),
                  Container(height: 1, width: 20, color: AppColors.borderSubtle),
                  const SizedBox(height: 4),
                  Text(_kInstallHint,
                     style: const TextStyle(
                       color: AppColors.accentCyan,
                       fontSize: 9,
                       fontWeight: FontWeight.bold,
                       fontFamily: 'RobotoMono'
                     )
                   ),
                   Text("ID: $shareId",
                     style: const TextStyle(
                       color: AppColors.textDisabled,
                       fontSize: 7,
                       fontFamily: 'RobotoMono'
                     )
                   ),
               ]
             ],
          ),
        ),
      ],
    );
  }
  
  static String _formatTierLabel(String label) {
    // Clean up label if needed, or simple pass through.
    return label.toUpperCase();
  }
}

