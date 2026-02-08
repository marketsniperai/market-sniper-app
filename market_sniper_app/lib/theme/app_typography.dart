import 'package:flutter/material.dart';
import 'app_colors.dart';

import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  const AppTypography._();

  /// Calculates a safe text scale factor clamped between 1.0 and 1.35.
  static double getScaleFactor(BuildContext context) {
    final double userScale = MediaQuery.textScalerOf(context).scale(1.0);
    return userScale.clamp(1.0, 1.35);
  }

  // --- Specialized Roles ---

  static TextStyle logo(BuildContext context, Color color) {
    // Unique SORA font for the brand logo
    return GoogleFonts.sora(
      fontSize: 20 * getScaleFactor(context),
      fontWeight: FontWeight.bold,
      color: color,
      letterSpacing: -0.5,
    );
  }

  // --- Roles defined by scale logic ---

  static TextStyle headline(BuildContext context) {
    return _base(context, 24, FontWeight.bold, AppColors.textPrimary);
  }

  static TextStyle title(BuildContext context) {
    return _base(context, 18, FontWeight.w600, AppColors.textPrimary);
  }

  static TextStyle body(BuildContext context) {
    return _base(context, 16, FontWeight.normal, AppColors.textSecondary);
  }

  static TextStyle caption(BuildContext context) {
    return _base(context, 12, FontWeight.normal, AppColors.textDisabled);
  }

  static TextStyle label(BuildContext context) {
    return _base(context, 14, FontWeight.w500, AppColors.textPrimary);
  }

  static TextStyle badge(BuildContext context) {
    return _base(context, 10, FontWeight.bold, AppColors.textPrimary,
        isBadge: true);
  }

  // --- Helper ---

  static TextStyle _base(
      BuildContext context, double size, FontWeight weight, Color color,
      {bool isBadge = false}) {
    double scale = getScaleFactor(context);
    if (isBadge) {
      scale = scale.clamp(1.0, 1.2);
    }
    // Use INTER for all UI elements
    return GoogleFonts.inter(
      fontSize: size * scale,
      fontWeight: weight,
      color: color,
    );
  }

  // --- Canonical Command Center Mono (D61.3) ---

  static TextStyle monoHero(BuildContext context) {
    return _baseMono(context, 16, FontWeight.bold, AppColors.textPrimary);
  }

  static TextStyle monoTitle(BuildContext context) {
    return _baseMono(context, 14, FontWeight.bold, AppColors.textPrimary);
  }

  static TextStyle monoBody(BuildContext context) {
    return _baseMono(context, 12, FontWeight.normal, AppColors.textSecondary);
  }

  static TextStyle monoTiny(BuildContext context) {
    return _baseMono(context, 10, FontWeight.normal, AppColors.textSecondary);
  }

  static TextStyle monoLabel(BuildContext context) {
    return _baseMono(context, 10, FontWeight.bold, AppColors.textPrimary,
        letterSpacing: 0.5);
  }

  static TextStyle _baseMono(
      BuildContext context, double size, FontWeight weight, Color color,
      {double? letterSpacing}) {
    double scale = getScaleFactor(context);
    return GoogleFonts.robotoMono(
      fontSize: size * scale,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
