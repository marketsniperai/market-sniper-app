# Runtime Verification Note
**Feature:** HF24 — Time-Traveller Chart v1
**Date:** 2026-01-28

## Verification Context
Headless environment. Verification relies on static analysis and logic inspection.

## Logic Verification
1.  **Dependencies:** `TimeTravellerChart` integrated into `OnDemandPanel`.
2.  **Data Wiring:**
    - `_buildTimeTravellerChart` extracts series from `rawPayload['series']`.
    - Handles missing data by defaulting to empty lists -> Triggers "CALIBRATING" state (Sine wave).
3.  **10:30 AM Rule (DAILY):**
    - `_isDailyLocked` calculation hoisted and passed to `TimeTravellerChart`.
    - Chart painter checks `isLocked`:
        - if `true`: Does NOT render future ghost candles.
        - if `false`: Renders future ghost candles with Reveal Animation.
    - Overlay: "LOCKED" badge shown in chart stack if `isLocked`.
4.  **UI Discipline:**
    - Uses `AppColors` tokens (NeonCyan, MarketBull/Bear).
    - Uses `AppTypography`.
    - `withValues` used instead of `withOpacity`.

## Limitations
- Visual confirmation of the "Sequential Reveal" animation requires manual testing.
- Visual confirmation of "LOCKED" overlay requires manual testing during 09:30-10:30 ET window.
