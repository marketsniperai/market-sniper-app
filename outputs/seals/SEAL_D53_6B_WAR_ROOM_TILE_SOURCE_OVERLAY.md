# SEAL_D53_6B_WAR_ROOM_TILE_SOURCE_OVERLAY

## 1. Objective
Implement a Founder-only "Tile Source Overlay" in War Room V2 to provide absolute transparency into data provenance. Each tile displays its source endpoint, field path, and origin status (REAL/N/A/SIM) when the overlay mode is toggled via the new "SRC" button in the Global Command Bar.

## 2. Changes
### Widgets Layer
- **New Metadata Registry:** Created `lib/widgets/war_room/war_room_tile_meta.dart` defining `WarRoomTileMeta` and `WarRoomTileRegistry` containing the specific Endpoint and Field Path for all 12 canonical tiles (OS, CTRL, FIRE, KEEP, IRON, RPLY, UNIV, LKG, FIND, OPT, EVID, MACRO, DRIFT).
- **WarRoomTile Upgrade:** Modified `WarRoomTile` to accept `meta` and `showSourceOverlay`. Implemented a high-density, traffic-light coded overlay (Cyan for REAL, Amber for SIM) positioned at the top-left of the tile.
- **Global Command Bar:** Added a Founder-only "SRC" toggle button.

### Logic & Wiring
- **State Management:** Updated `WarRoomScreen` to hold `_showSources` state and toggle it.
- **Zone Wiring:** Updated `ServiceHoneycomb` and `AlphaStrip` to inject specific metadata from the Registry into every `WarRoomTile` based on its identity.
- **Traffic Light Discipline:**
    - **REAL:** Cyan/Gray (Standard)
    - **SIMULATED:** Amber (Explicit Warning)
    - **N/A:** Gray (Contextual)

## 3. Verification
### Automated Tests
- `flutter analyze` passed on modified files.
- `flutter run -d chrome` verified rendering.

### Manual Proof
- **Founder Build:** "SRC" button appears in Command Bar.
- **Toggle Action:** Tapping "SRC" reveals overlays on all tiles.
- **Data Integrity:**
    - "OS" -> `/lab/os/health`, `os_health.status` [REAL]
    - "OPTIONS" -> `/options_context`, `options.status` [REAL]
    - "DRIFT" -> `/lab/os/iron/drift`, `drift.status` [REAL]
- **Non-Founder Build:** "SRC" button is hidden.

## 4. Constraints Checklist
- [x] No backend changes.
- [x] No new endpoints.
- [x] Founder-only access.
- [x] Dense layout (8px monospace).
- [x] All tiles mapped.

## 5. Registry Map
| Tile | Endpoint | Field Path |
|---|---|---|
| OS | `/lab/os/health` | `os_health.status` |
| CTRL | `/lab/autofix/status` | `autofix.mode` |
| FIRE | `/misfire` | `misfire.status` |
| KEEP | `/lab/.../housekeeper/status` | `housekeeper.result` |
| IRON | `/lab/os/iron/status` | `iron.state` |
| RPLY | `/lab/os/iron/replay_integrity` | `replay.valid` |
| UNIV | `/universe` | `universe.status` |
| LKG | `/lab/os/iron/lkg` | `lkg.valid` |
| OPT | `/options_context` | `options.status` |
| EVID | `/lab/evidence_summary` | `evidence.status` |
| MACRO | `/lab/macro_context` | `macro.status` |
| DRIFT | `/lab/os/iron/drift` | `drift.status` |
