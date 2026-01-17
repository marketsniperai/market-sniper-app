# SEAL: D38.06 - Iron OS Tile (State + Details)
**Date:** 2026-01-16
**Author:** Antigravity (Agent)
**Authority:** D36.03 (System Language)
**Strictness:** HIGH

## 1. Summary
This seal certifies the upgrade of the **Iron OS Tile** to a comprehensive state monitor. It now renders critical resilience data including State, Last Tick, Rollback history, Replay history, and Timeline Tail availability.

## 2. Implementation
- **API:** Relies on `/lab/os/iron/status` (existing or future) as the single source of truth.
- **Models:** Expanded `IronSnapshot` to include state machine fields (`state`, `lastTick`, `lastRollback`, `lastReplay`, `timeline`).
- **UI:** Updated `WarRoomTile` to render 5-row compact summary.
    - **Color Rules:**
        - **Green:** Nominal (State + No Rollback/Replay active).
        - **Orange:** Partial data or recent Rollback (Warning).
        - **Red:** Unavailable or Incident.

## 3. Verification
- **Discipline:** `verify_project_discipline.py` PASSED.
- **Analysis:** `flutter analyze` PASSED (0 issues).
- **Build:** `flutter build web` PASSED.

## 4. Governance
- **Truthful Degradation:** If endpoint is missing (JSON empty), explicitly renders "UNAVAILABLE" and "Endpoint missing".
- **No Guessing:** State defaults to "IDLE" or "DISCONNECTED" only when backed by data or lack thereof.
