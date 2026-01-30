# Implementation Plan - Menu Entry Polish (D45.POLISH.MENU.ENTRY.01)

## Goal
Increase discovery of the Partner Protocol by adding a subtle "Partner Protocol (Beta)" signal to the Account menu entry, using institutional styling (neon cyan, faint opacity).

## Proposed Changes

### [market_sniper_app]

#### [MODIFY] [menu_screen.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/screens/menu_screen.dart)
- Update `_buildMenuItem` to accept an optional `subtitle` or `trailingBadge`.
- OR locally modify the "Account" invocation to use a custom builder if `_buildMenuItem` is too rigid.
- **Decision:** Enhance `_buildMenuItem` to support `String? subtitle`.
- **Styling:**
  - Subtitle Text: "Partner Protocol (Beta)"
  - Color: `AppColors.neonCyan.withValues(alpha: 0.6)`
  - Font: `GoogleFonts.inter` (10-11px).
  - Layout: Column inside the Row (Title \n Subtitle).

## Verification Plan

### Automated
- `flutter analyze` ensuring no syntax errors.

### Manual Verification
- `flutter run -d chrome`.
- Navigate to Menu.
- Verify "Account" row shows the new subtitle.
- Verify alignment, color, and opacity.
- Verify tap still works.
