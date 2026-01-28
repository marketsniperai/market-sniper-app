# Runtime Verification Logic Note
**Feature:** HF23 — On-Demand Timeframe Control (DAILY/WEEKLY)
**Date:** 2026-01-28

## Verification Context
Since this environment is headless, visual confirmation (screenshots) and manual interaction (tapping tabs) cannot be captured directly. Verification relies on:
1.  **Static Analysis:** `flutter analyze` passing with no issues.
2.  **Compilation:** `flutter build web` completing successfully.
3.  **Code Inspection:**
    - `api_client.dart`: Confirmed addition of `timeframe` parameter to `fetchOnDemandContext`.
    - `on_demand_panel.dart`: Confirmed implementation of `_buildTimeframeTab` (Selector UI) and `_buildLockBannerIfNeeded` (10:30 AM logic).
    - `on_demand_panel.dart`: Confirmed `_analyze()` calls `api.fetchOnDemandContext` with the selected `_timeframe`.

## Logic Verification
- **Selector:** The UI renders two tabs: DAILY (Neon Cyan) and WEEKLY (Gold/Stale). Tapping a tab updates `_timeframe` and triggers `_analyze()` if a ticker is present.
- **10:30 AM Rule (DAILY):**
    - The code calculates `nowEt` (UTC - 5).
    - Checks if `_timeframe == "DAILY"` AND `09:30 <= nowEt < 10:30`.
    - If true, displays the `LOCKED` banner: "INITIAL BALANCE FORMING. AI CALIBRATION IN PROGRESS."
- **WEEKLY Framework:**
    - The API call sends `timeframe=WEEKLY`.
    - The Backend (Stub/Real) is expected to return Weekly context.
    - If the backend is not yet Weekly-aware, it may ignore the param (fallback) or return N/A, which is safe.
    - The "LOCKED" banner logic *explicitly* checks `_timeframe == "DAILY"`, so WEEKLY behaves as a demo series (always open), satisfying the objective.

## Limitations
- **Visual Proof:** Visual verification of the Cyan/Gold colors and the Lock Banner is deferred to a future manual check by the Founder.
- **Backend Response:** Assuming backend handles `timeframe` parameter gracefully (or ignores it safely).
