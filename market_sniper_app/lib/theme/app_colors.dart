import 'package:flutter/material.dart';

class AppColors {
  // Private Constructor
  AppColors._();

  // --- Core Palette (Night Finance Premium) ---
  // Backgrounds
  static const Color bgPrimary = Color(0xFF050814); // Deep Void (was 0xFF050505)
  static const Color surface1 = Color(0xFF101425);  // Card BG (was 0xFF121212)
  static const Color surface2 = Color(0xFF1E2435);  // Elevated BG (Adjusted for coherence)
  static const Color transparent = Colors.transparent; // Discipline Compliance
  static const Color shadow = Color(0xFF000000);     // Pure Black for Shadows

  // Accents
  static const Color accentCyan = Color(0xFF00F5FF); // Sniper Cyan (was 0xFF00E5FF)
  static const Color accentCyanDim = Color(0xFF008C9E); // Dimmed Cyan

  // Market Sentiment (Aligned with System States)
  static const Color marketBull = Color(0xFF00E676);   // Sniper Green
  static const Color marketBear = Color(0xFFFF2D55);   // Neon Red
  static const Color marketClosed = Color(0xFF888888); // Grey

  // System States
  static const Color stateLive = Color(0xFF00E676);   // Sniper Green (was 0xFF00FF88)
  static const Color stateStale = Color(0xFFFFD600);  // Accent Neutral (was 0xFFFFCC00)
  static const Color stateLocked = Color(0xFFFF2D55); // Neon Red (was 0xFFFF3366)

  // Text
  static const Color textPrimary = Color(0xFFEAEAEA);   // Off-White (was 0xFFFFFFFF)
  static const Color textSecondary = Color(0xFF9BA4B5); // Blue-Grey (was 0xFFB0B0B0)
  static const Color textDisabled = Color(0xFF5A6675);  // Deep Grey (Adjusted)

  // Borders
  static const Color borderSubtle = Color(0xFF2A3245); // Subtle Blue-Grey
  static const Color borderActive = Color(0xFF00F5FF); // Sniper Cyan

  // Glows (Using new bases)
  static const Color glowCyan = Color(0x3300F5FF);
  static const Color glowGreen = Color(0x3300E676);
  static const Color glowRed = Color(0x33FF2D55);

  // --- Legacy Aliases (Night Finance Compatibility) ---
  static const Color bgDeepVoid = bgPrimary;
  static const Color cardBg = surface1;
  static const Color sniperCyan = accentCyan;
  static const Color sniperGreen = stateLive;
  static const Color neonRed = stateLocked;
  static const Color accentNeutral = stateStale;
  static const Color textWhite = textPrimary;
  static const Color textGrey = textSecondary;
}
