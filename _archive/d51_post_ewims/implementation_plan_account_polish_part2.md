# Implementation Plan - Account Screen Polish (D45.POLISH.03) - Part 2

## Goal
Further polish the Account screen by unifying the card styling (Partner Protocol matches User Card), updating copy, refining typography, and converting the Log Out action to a simple button.

## Proposed Changes

### [market_sniper_app]

#### [MODIFY] [account_screen.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/screens/account_screen.dart)
- **Refactor:** Extract the `Container` > `BoxDecoration` logic from the User/Plan card into a reusable `_buildPremiumCard({required Widget child})` method.
  - This ensures exact visual identity (gradient, border, shadow, radius).
- **Partner Protocol Card:**
  - Update `_buildPartnerProtocolCard` to use `_buildPremiumCard` instead of `NeonOutlineCard`.
  - **Copy:** Update activation text to "10 eligible operators required to activate Partner Credits."
  - **Badges:**
    - Use `AppTypography.badge(context)` for labels.
    - Remove `GoogleFonts` overrides.
    - Tighten row spacing (remove loose `MainAxisAlignment.spaceBetween`, use `SizedBox(width: 8)` or similar).
    - Ensure inactive badges use `AppColors.textSecondary` or `textDisabled`.
- **Log Out:**
  - Remove the "Account Actions" `NeonOutlineCard`.
  - Replace with a centered `OutlinedButton` or string-styled `TextButton`: "Log Out".
  - Style: `AppColors.marketBear` (or muted red) text.

## Verification Plan

### Automated
- Run `flutter analyze` to ensure no errors.

### Manual Verification
- Run `flutter run -d chrome`.
- Verify:
  - Partner Protocol card looks *identical* to User card in shape/color.
  - Text says "10 eligible operators...".
  - Badges use standard font and are tighter.
  - Log Out is a button, not a card.
