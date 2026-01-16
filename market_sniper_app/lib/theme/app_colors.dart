import 'package:flutter/material.dart';

class AppColors {
  // Private Constructor
  AppColors._();

  // --- Core Palette (Sergio's Hex Values preserved) ---
  // Backgrounds
  static const Color bgPrimary = Color(0xFF050505); // Deepest Black
  static const Color surface1 = Color(0xFF121212); // Card BG
  static const Color surface2 = Color(0xFF1E1E1E); // Elevated BG

  // Accents
  static const Color accentCyan = Color(0xFF00E5FF); // Cyber Cyan
  static const Color accentCyanDim = Color(0xFF008C9E); // Dimmed Cyan

  // Market Sentiment
  static const Color marketBull = Color(0xFF00FF88); // Electric Green
  static const Color marketBear = Color(0xFFFF3366); // Neon Red/Pink
  static const Color marketClosed = Color(0xFF888888); // Grey

  // System States
  static const Color stateLive = Color(0xFF00FF88); // Active/Live
  static const Color stateStale = Color(0xFFFFCC00); // Warning/Stale
  static const Color stateLocked = Color(0xFFFF3366); // Error/Locked

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF666666);

  // Borders
  static const Color borderSubtle = Color(0xFF333333);
  static const Color borderActive = Color(0xFF00E5FF);

  // Glows (Optional usage)
  static const Color glowCyan = Color(0x3300E5FF);
  static const Color glowGreen = Color(0x3300FF88);
  static const Color glowRed = Color(0x33FF3366);
}
