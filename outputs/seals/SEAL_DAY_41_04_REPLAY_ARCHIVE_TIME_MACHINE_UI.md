# SEAL: D41.04 - Replay Archive + Time Machine UI (OS.R2.1)

> [!IMPORTANT]
> **Status:** SEALED
> **Date:** 2026-01-22
> **Author:** ANTIGRAVITY

## 1. Feature
**Replay Archive & Time Machine**
- **Persistence:** Local JSONL archive (`outputs/runtime/os_replay_archive.jsonl`) storing the last 30 replay attempts.
- **UI:** "Time Machine" modal in War Room allowing Founder to browse and select past replay contexts.
- **Integration:** Wired to D41.03 Replay Tile for seamless history access.

## 2. Implementation
### Backend
- **Module:** `backend/os_ops/replay_archive.py` (Bounded to 30 entries).
- **Endpoint:** `GET /lab/replay/archive/tail` in `api_server.py`.
- **Logging:** Stub execution in D41.03 now creates an archive entry.

### Frontend
- **Actions:** Added History icon to `ReplayControlTile`.
- **Modal:** Implemented `_showTimeMachine` fetching archive tail.
- **Interaction:** Tapping an entry prefills `_selectedDate` and status.

## 3. Verification
- **Storage:** Verified JSONL creation and appended logs.
- **UI:** Verified modal display and list rendering.
- **Analysis:** Codebase compliant.

## 4. Manifest
- `backend/os_ops/replay_archive.py`
- `backend/api_server.py` (Updates)
- `market_sniper_app/lib/widgets/war_room/replay_control_tile.dart` (Updates)
- `outputs/proofs/day_41/ui_replay_archive_time_machine_proof.json`

## 5. Next Steps
- D41.05: Founder-Gated Rollback UI.
