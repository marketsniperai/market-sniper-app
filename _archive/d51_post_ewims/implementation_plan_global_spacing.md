# Implementation Plan - Global Spacing Standardization (D45.POLISH.SPACING.01)

## Goal
Unify vertical spacing and visual weight across the OS by applying canonical `AppSpacing` tokens and reducing the visual weight of secondary actions.

## Proposed Changes

### [market_sniper_app]

#### [NEW] [lib/theme/app_spacing.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/theme/app_spacing.dart)
- Define `cardGap` (16), `sectionGap` (24), `actionGap` (10).

#### [MODIFY] [account_screen.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/screens/account_screen.dart)
- **Import:** `app_spacing.dart`.
- **Layout:** Replace raw `SizedBox(height: X)` with `AppSpacing.gapCard`, `AppSpacing.gapSection`.
- **Visual Weight:** 
  - Convert `Settings`, `Help`, and `Logout` cards from "Premium/Neon Cards" to lighter `OutlinedButton` or `TextButton` rows (or lightweight container).
  - Keeps the top "Identity" and "Partner Protocol" cards heavy (Premium).

#### [MODIFY] [menu_screen.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/screens/menu_screen.dart)
- **Import:** `app_spacing.dart`.
- **Layout:** Standardize gaps between menu items to `AppSpacing.actionGap` (10px) or `cardGap` (16px) depending on grouping.
- **Section Headers:** Use `AppSpacing.gapSection` (24px).

## Verification Plan

### Automated
- `flutter analyze`

### Manual Verification
- `flutter run -d chrome`
- **Account Screen:** Verify gaps are 16px/24px. Verify "Logout" is no longer a heavy card.
- **Menu Screen:** Verify consistent breathing room.
