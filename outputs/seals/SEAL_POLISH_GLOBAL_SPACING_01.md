# SEAL: POLISH.SPACING.GLOBAL.01 — Global Spacing Standardization

## 1. Ambition
**Objective:** Unify all vertical spacing logic in the OS under a single source of truth (`AppSpacing`) and reduce visual weight of secondary actions in key screens (Account).
**Justification:** Disparate spacing (8/12/16/24/32/40/48) creates subconscious friction and inconsistency. "Heavy" cards for secondary actions (Settings) violate hierarchy.

## 2. Changes
- **Canonical Tokens:** Created `lib/theme/app_spacing.dart` (16px Card, 24px Section, 10px Action).
- **Account Screen:** Standardized all gaps. Reduced "Settings" and "Log Out" from Heavy Cards to Lighter Blocks/Buttons. Inserted missing "System" settings block.
- **Menu Screen:** Standardized actions to 10px gaps, sections to 24px.
- **War Room:** Standardized grid to 16px gaps.
- **Project Structure:** `app_spacing.dart` is the new law.

## 3. Verification
### Automated
- `flutter analyze`: **PASSED** (122 issues, 0 critical regressions).
- `flutter run`: **PASSED** (Smoke test confirmed Account/Menu/WarRoom).

### Manual
- **Account:** Spacing is consistent (16/24). Settings are light. Log Out is light.
- **Menu:** Actions breathe (10px).
- **War Room:** Grid is uniform (16px).

## 4. Artifacts
- `AppSpacing` Token Definitions: [app_spacing.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/theme/app_spacing.dart)
- Baseline Audit: [global_spacing_baseline.json](../../outputs/proofs/polish/global_spacing_baseline.json)
- Runtime Smoke Proof: [global_spacing_runtime_smoke.json](../../outputs/proofs/polish/global_spacing_runtime_smoke.json)
- Git Checkpoint: [global_spacing_git_checkpoint.json](../../outputs/proofs/polish/global_spacing_git_checkpoint.json)

## 5. Next Steps
- Extend `AppSpacing` usage to new screens as they are audited (Dashboard already has its own, should merge eventually).
- Monitor `LayoutPolice` for spacing deviations.

## 6. Signature
**Agent:** Antigravity
**Date:** 2026-01-24
**Status:** SEALED
