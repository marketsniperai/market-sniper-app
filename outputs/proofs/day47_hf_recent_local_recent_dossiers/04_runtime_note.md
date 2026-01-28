# Runtime Verification Note
**Feature:** HF-RECENT-LOCAL — Recent Dossiers (Local Snapshot)
**Date:** 2026-01-28

## Verification Context
Headless environment. Verification relies on logic inspection and sample storage dump simulation.

## Logic Verification
1.  **Dependencies:** `RecentDossierStore` + `RecentDossierRail` + `OnDemandPanel`.
2.  **Logic:**
    - **Store:** `RecentDossierStore` uses `path_provider` to write `recent_dossiers_v1.json`.
    - **Cap:** Logic verified to cap at 10 items (`_maxItems = 10`).
    - **Dedupe:** Logic verified to remove existing `(ticker, timeframe)` before inserting new at front.
    - **Integration:**
        - `_analyze` success -> `_recentStore.record(...)`.
        - UI Rail -> `onTap` -> calls `_loadFromSnapshot(...)`.
        - `_loadFromSnapshot` -> sets `_result` from payload, bypasses API (`_isAnalyzing = false`).
3.  **UI Logic:**
    - `RecentDossierRail` renders items.
    - Top of Panel shows "LOADED FROM LOCAL SNAPSHOT" if loaded via rail.

## Limitations
- Actual file I/O requires simulator/device.
