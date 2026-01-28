
# SEAL_D47_HF19_PROJECTION_INPUTS_WIRING
**Date:** 2026-01-27
**Author:** Antigravity (Agent)
**Status:** SEALED
**Time:** 15:15 EST

## 1. Objective
Wire existing Intelligence Engines (Options, News, Macro) into `ProjectionOrchestrator` to influence the projection envelope ("volatility scale") and scenario notes ("qualitative tilt"), moving beyond simple Demo randomness while maintaining safety (no fake predictions).

## 2. Execution Log
1.  **Backend - `intraday_series_source.py`**:
    *   Added `volatility_scale` parameter to `generate_series` and `load`.
    *   Logic: Scales the random walk volatility base (0.2%) by the factor.
2.  **Backend - `projection_orchestrator.py`**:
    *   **Inputs Wired**:
        *   `options_context.json`: Reads IV Rank/Status.
        *   `macro_context.json`: Checks availability.
        *   `news_digest.json`: Checks availability/counts.
    *   **Logic Implemented**:
        *   `inputs_used`: Lists active engines (PROJECTION_DEMO, OPTIONS, NEWS, etc.).
        *   `missing_inputs`: explicit list of what's N/A.
        *   `volatility_scale`: 1.5x if IV High, 0.8x if IV Low, 1.0x default.
        *   `scenario_notes`: Appends context notes (e.g., "Elevated IV detected").
3.  **Frontend**:
    *   No changes required (Backend-driven artifact updates are naturally consumed).

## 3. Verification
*   `projection_report.json`: Validated new fields (`inputs_used`, `missing_inputs`, `events`).
*   `intraday_series_source.py`: Validated call signature update.
*   **Behavior Check**:
    *   If Options N/A -> scale=1.0.
    *   If Options High IV -> scale=1.5. (Implied/Logic verified).

## Pending Closure Hook
Resolved Pending Items: None
New Pending Items: None
