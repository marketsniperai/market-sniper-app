# SEAL: D42.09 — Before/After Diff Surface

## Status: SEALED
## Date: 2026-01-17
## Proof: outputs/runtime/day_42/day_42_09_before_after_diff_proof.json

## Description
Implemented the Before/After Diff Surface for the War Room, enabling forensic visibility into Self-Heal operations. This feature exposes a read-only record of state changes (diffs) sourced strictly from the canonical artifact `outputs/os/os_before_after_diff.json`.

## Implementation Details

### Backend
- **IronOS Engine**: Added `get_before_after_diff()` static method to `IronOS` class.
- **Models**: Defined `BeforeAfterDiffSnapshot` Pydantic model.
- **API Server**: Added `GET /lab/os/self_heal/before_after` endpoint (Strict Lens). Returns 404 if artifact missing/invalid.

### Frontend
- **War Room Snapshot**: Added `BeforeAfterDiffSnapshot` model and `beforeAfterDiff` field.
- **ApiClient**: Added `fetchBeforeAfterDiff()`.
- **Repository**: Integrated diff fetching into `WarRoomRepository.fetchSnapshot`.
- **UI**: Added `_buildBeforeAfterTile` to `WarRoomScreen` and modified `WarRoomTile` to support `customBody` for flexible internal rendering (allowing scrollable/collapsible content).
- **Visualization**: The tile displays:
    - Timestamp & Operation ID
    - List of Changed Keys (if provided)
    - Collapsible "BEFORE" and "AFTER" JSON views (using `ExpansionTile` inside a scrollable container).

## Verification
- **Logic Verification**: `verify_before_after_proof.py` PASSED (Missing -> 404, Valid -> 200 + Content).
- **Project Discipline**: `verify_project_discipline.py` PASSED.
- **Code Analysis**: `flutter analyze` PASSED (no new regressions).

## Governance
- **Visibility Only**: The surface provides raw data transparency. It makes no claims of "improvement" or "resolution".
- **Strict Mirror**: UI perfectly mirrors the artifact state.
- **Fallback**: Missing artifact results in "UNAVAILABLE" tile state.

## Notes
- `WarRoomTile` was refactored to support `customBody` to enable the specific "Collapsible Sections" requirement without breaking existing tiles or creating a separate divergent widget.
