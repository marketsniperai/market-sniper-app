import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class WatermarkService {
  static const String _kSlogan = "Institutional Power... In Your Pocket.";

  static Widget applyWatermark(BuildContext context, Widget content, {String tierLabel = "PREVIEW"}) {
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
               Text(_kSlogan, 
                 style: const TextStyle(
                   color: AppColors.textSecondary,
                   fontSize: 10,
                   fontStyle: FontStyle.italic,
                   fontWeight: FontWeight.bold,
                   fontFamily: 'RobotoMono'
                 )
               ),
               const SizedBox(height: 2),
               Text("MARKETSNIPER.AI | $tierLabel", 
                 style: const TextStyle(
                   color: AppColors.textDisabled,
                   fontSize: 8,
                   fontFamily: 'RobotoMono'
                 )
               )
             ],
          ),
        ),
        // Optional: Watermark logo or overlay could go here
      ],
    );
  }
}
