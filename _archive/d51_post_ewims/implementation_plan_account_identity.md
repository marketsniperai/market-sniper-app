# Implementation Plan - Account Identity Polish (D45.POLISH.ACCOUNT.IDENTITY.01)

## Goal
Establish emotional continuity between Welcome and Account screens by adding a micro-line of copy "Founder privileges active" below the "My Account" header.

## Proposed Changes

### [market_sniper_app]

#### [MODIFY] [account_screen.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/screens/account_screen.dart)
- **Header Structure:** Convert the Title `Text` widget in the header `Row` into a centered `Column`.
- **New Element:** Add "Founder privileges active" `Text` widget below "My Account".
- **Styling:**
  - `AppTypography.caption`
  - Color: `AppColors.textSecondary.withValues(alpha: 0.7)`
  - Letter Spacing: 0.5
  - Size: 10px (implied by caption/constraints)
- **Constraint Compliance:** Ensure no extraneous icons or logic.

## Verification Plan

### Automated
- `flutter analyze`

### Manual Verification
- `flutter run -d chrome`
- Verify header appearance:
  - "My Account" remains centered relative to the column.
  - Subtext appears directly below.
  - Header height is minimal.
