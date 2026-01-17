# SEAL: D38.03 - Autofix Control Plane Tile
**Date:** 2026-01-16
**Author:** Antigravity (Agent)
**Authority:** D36.03 (System Language)
**Strictness:** HIGH

## 1. Summary
This seal certifies the upgrade of the **Autopilot War Room Tile** into a functional **Control Plane Summary**. It now renders truthful, detailed status from the backend's Autofix and Housekeeper modules without adding execution controls (rendering only).

## 2. Implementation
- **Models:** Expanded `AutopilotSnapshot` to capture `mode`, `stage`, `lastAction`, `cooldown`, and `housekeeper` data.
- **Repository:** `WarRoomRepository` now intelligently merges `/lab/autofix/status` and `/lab/housekeeper/status`.
    - Handles missing endpoints gracefully (returns UNAVAILABLE).
    - Maps `dial` / `mode` correctly.
- **UI:** `WarRoomTile` now uses a structured line-based layout for the Control Plane.
    - **Color Rules:**
        - **Green:** SAFE_AUTOPILOT, SHADOW, FULL_AUTOPILOT
        - **Orange:** OFF (if Housekeeper disabled), Degraded
        - **Red:** Unavailable / Disconnected

## 3. Verification
- **Discipline:** `verify_project_discipline.py` PASSED (including D38.01.2 layout rules).
- **Analysis:** `flutter analyze` PASSED (0 issues).
- **Build:** `flutter build web` PASSED.

## 4. Governance
- **Truth in UI:** The tile displays "UNAVAILABLE" if endpoints are missing, never fabrication.
- **No Buttons:** Strict exclusion of action buttons adhered to.
