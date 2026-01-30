# Implementation Plan - Partner Progress Polish (D45.POLISH.PARTNER.PROGRESS.01)

## Goal
Add an emotional progress indicator to the Partner Protocol card (Front) using a minimal progress bar and verified operator count, without exposing monetary values.

## Proposed Changes

### [market_sniper_app]

#### [MODIFY] [account_screen.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/screens/account_screen.dart)
- **Target Widget:** `_buildPartnerProtocolFront`.
- **New Elements:**
  - `LinearProgressIndicator`:
    - Height: 2px.
    - Value: 0.2 (2/10).
    - Color: `AppColors.neonCyan`.
    - Background: `AppColors.textDisabled.withOpacity(0.1)`.
  - `Text`:
    - "2 / 10 verified operators".
    - `AppTypography.caption`.
    - `AppColors.textSecondary`.
- **Placement:** Insert below the Tier Badges `Row`, replacing the current "10 eligible operators..." text with this more dynamic layout (or augmenting it).
- **Refinement:** Use `SizedBox` for tight vertical spacing.

## Verification Plan

### Automated
- `flutter analyze`

### Manual Verification
- `flutter run -d chrome`
- Verify Partner Protocol Card (Front):
  - Progress bar renders thin (2px) and cyan.
  - Text "2 / 10 verified operators" appears below.
  - Layout does not overflow.
