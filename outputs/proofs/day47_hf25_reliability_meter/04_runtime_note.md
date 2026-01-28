# Runtime Verification Note
**Feature:** HF25 — Reliability Meter
**Date:** 2026-01-28

## Verification Context
Headless environment. Verification relies on logic inspection and sample payload validation.

## Logic Verification
1.  **Dependencies:** `ReliabilityMeter` integrated into `OnDemandPanel`.
2.  **State Logic:**
    - **Locked (09:30-10:30 ET):** Forces `CALIBRATING`.
    - **Backend State:**
        - `OK`: Check Samples.
            - > 30 -> `HIGH`
            - > 10 -> `MED`
            - Else -> `LOW`
        - `INSUFFICIENT_DATA` -> `LOW`
        - `PROVIDER_DENIED` -> `LOW`
        - Else -> `CALIBRATING`
3.  **Active Inputs:** Calculated as `Total (4) - missingInputs.length`.
4.  **UI Discipline:**
    - Uses `AppColors` tokens (Live, Stale, Bear, NeonCyan).
    - Uses `AppTypography` labels.
5.  **Placement:** Successfully inserted below `TimeTravellerChart`.

## Limitations
- Visual confirmation of "LOCKED" state requires manual testing.
- Visual confirmation of chips requires backend payload with populated evidence.
