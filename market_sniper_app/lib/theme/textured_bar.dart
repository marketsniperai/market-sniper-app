import 'package:flutter/material.dart';
import 'app_colors.dart';

class TexturedBarBackground extends StatelessWidget {
  final Widget child;
  final double imageOpacity;
  final double overlayOpacity;

  const TexturedBarBackground({
    super.key,
    required this.child,
    this.imageOpacity = 0.22, // Default safe start
    this.overlayOpacity = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary, // Base black
        image: DecorationImage(
          image: const AssetImage('assets/textures/leather_midnight.png'),
          fit: BoxFit.cover,
          scale: 1.0, // Tiling control if needed, cover is usually enough for bars
          opacity: imageOpacity,
        ),
      ),
      child: Stack(
        children: [
          // Overlay layer to keep it subtle and premium (not noisy)
          Container(
            color: AppColors.bgPrimary.withOpacity(overlayOpacity),
          ),
          // Actual content (AppBar/NavBar)
          child,
        ],
      ),
    );
  }
}
