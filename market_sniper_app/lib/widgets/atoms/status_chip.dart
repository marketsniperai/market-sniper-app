import 'package:flutter/material.dart';
import 'package:market_sniper_app/theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isOutline;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(4),
        border: isOutline ? Border.all(color: color) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isOutline
              ? color
              : AppColors.bgPrimary, // Contrast text if filled
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
