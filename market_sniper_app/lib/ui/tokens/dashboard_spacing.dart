import 'package:flutter/material.dart';

class DashboardSpacing {
  // Private constructor
  DashboardSpacing._();

  // Root screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);

  // Standard Card Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  // Vertical margin between cards
  static const EdgeInsets cardMargin = EdgeInsets.only(bottom: 16.0);

  // Specific padding for dense items (like banners)
  static const EdgeInsets densePadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  // Standard gaps
  static const double gapSmall = 8.0;
  static const double gap = 16.0;
  static const double gapLarge = 24.0;
  static const double sectionGap = 32.0;

  // Visuals
  static const double cornerRadius = 12.0;
  static const double borderWidth = 1.0;

  // Padding Helpers (to avoid EdgeInsets literals in UI code)
  static const EdgeInsets paddingSmall = EdgeInsets.all(gapSmall);
  static const EdgeInsets paddingDefault = EdgeInsets.all(gap);
  static const EdgeInsets bottomGap = EdgeInsets.only(bottom: gap);
  static const EdgeInsets bottomGapSmall = EdgeInsets.only(bottom: gapSmall);

  // Specific
  static const EdgeInsets founderSsoT = EdgeInsets.only(bottom: 12, left: 4);
  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 6);
}
