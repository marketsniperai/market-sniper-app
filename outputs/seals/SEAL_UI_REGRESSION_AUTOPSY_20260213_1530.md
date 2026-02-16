# SEAL: UI REGRESSION AUTOPSY — WAR ROOM VOLATILITY LOSS
**Date:** 2026-02-13
**Subject:** Missing Volatility Widget & Layout Regression in Command Center

## 1. Findings

### Phase A: Runtime Environment
- **Probes Injected**: Added `TRUTH_PROBE` logs to `main.dart` to verify `API_BASE_URL`, `FOUNDER_BUILD`, `WAR_ROOM_ACTIVE`, and `FOUNDER_KEY`.
- **Status**: Ready for runtime verification by user (flutter run output).

### Phase B: Web Auth Headers
- **Evidence**: Previous logs confirmed `WEB_LAB_AUTH: sending founder header`.
- **Snapshot Status**: `USP_FETCH_FAIL status=404` observed in previous run. This likely indicates backend path mismatch or data missing, but Auth logic is firing.

### Phase C: Root Cause Analysis (The "Crime Scene")
- **Missing File**: `lib/widgets/command_center/volatility_meter.dart` was **NOT FOUND** in the file system or recent git history.
    - *Verdict*: Accidental deletion or failure to commit during D61.6 refactor.
- **Layout Regression**: `CommandCenterScreen.dart` contained `MarketPressureOrb` but **missing** the `Row` wrapper and the `VolatilityMeter` widget, breaking the "Trinity HUD" (Quartet + Orb + Volatility) design spec.

## 2. Regression Impact
- **Visual**: Command Center HUD unbalanced (Left-heavy Orb, empty Right side).
- **Functional**: Users cannot see Volatility metrics.
- **System**: Compilation passed previously because the *import* was also missing, making it a silent logic regression rather than a build break.

## 3. Next Steps (Fix Forward)
- **Recreate**: implement `VolatilityMeter` from scratch (Trinity HUD specs).
- **Rewire**: Restore `Row` layout in `CommandCenterScreen`.
- **Verify**: Build and Analyze.

**Verdict**: CONFIRMED REGRESSION (Missing Asset & Code Drift).
