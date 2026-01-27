import 'package:flutter/material.dart';

/// Single Source of Truth for Layout Spacing.
/// Enforced by ANTIGRAVITY CONSTITUTION (D45.POLISH.SPACING.01).
class AppSpacing {
  AppSpacing._(); // Private constructor

  /// Vertical gap between primary cards in a stack.
  static const double cardGap = 16.0;

  /// Vertical gap between distinct logical sections.
  static const double sectionGap = 24.0;

  /// Vertical gap between lighter action rows.
  static const double actionGap = 10.0;

  /// Standard internal padding for cards.
  static const double cardInnerPadding = 16.0;

  // Tiny helpers for code cleanliness
  static const SizedBox gapCard = SizedBox(height: cardGap);
  static const SizedBox gapSection = SizedBox(height: sectionGap);
  static const SizedBox gapAction = SizedBox(height: actionGap);
}
