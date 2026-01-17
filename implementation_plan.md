# Implementation Plan - D37.08: Dashboard Degrade Rules

## Goal
Implement safe, institutional degrade rules for the Dashboard to ensure it never crashes and always renders a truthful "what is known" surface.

## Proposed Changes

### Logic
#### [NEW] [dashboard_degrade_policy.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/logic/dashboard_degrade_policy.dart)
- Enum `DegradeState` { ok, partial, stale, unavailable }
- Class `DashboardDegradePolicy`
- Method `evaluate(DashboardPayload? payload, ResolvedDataState dataState, String? fetchError)`
  - Returns `DegradeContext` (state, reasonCode, missingFields).
  - Logic:
    - If `fetchError` != null -> UNAVAILABLE
    - If `payload` == null -> UNAVAILABLE
    - If `dataState.state` == STALE -> STALE (or Locked -> STALE/UNAVAILABLE depending on severity? Prompt says "show LOCKED (already handled)". Degrade policy is for *data completeness*. Locked is a *status*. If Locked, data might be fine. So maybe OK but status is Locked. Prompt: "If DataStateResolver == LOCKED -> show LOCKED... but degrade policy may still be OK".
    - So DegradeState focuses on *availability* and *freshness* and *completeness*.
    - If `payload` missing required fields (runId, etc) -> PARTIAL.

### UI Components
#### [NEW] [degrade_banner.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/widgets/degrade_banner.dart)
- Visual warning strip if state != OK.
- Colors:
  - UNAVAILABLE: `AppColors.stateLocked` (Red)
  - STALE: `AppColors.stateStale` (Amber)
  - PARTIAL: `AppColors.accentCyanDim`? Or `stateStale`.
- Founder mode: Expose `reasonCode` and `missingFields`.

### Integration
#### [MODIFY] [dashboard_screen.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/screens/dashboard_screen.dart)
- Instantiate `DashboardDegradePolicy`.
- In `build`, evaluate policy.
- Insert `DegradeBanner` below FounderBanner/SessionStrip.
- Ensure `LastRunWidget` and `OSHealthWidget` handle nulls (they largely do, but double check `LastRunSnapshot.unknown` fallback).

## Verification
- **Automated**: `flutter analyze`.
- **Manual**: Simulate error (offline), verify banner.
- **Discipline**: `verify_project_discipline.py`.
