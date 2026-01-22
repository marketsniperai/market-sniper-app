# SEAL: D41.03 - Institutional Day Replay UI (OS.R2.0)

> [!IMPORTANT]
> **Status:** SEALED
> **Date:** 2026-01-22
> **Author:** ANTIGRAVITY

## 1. Feature
**Institutional Day Replay UI**
- A War Room surface allowing Founder to trigger a replay of a specific day's events.
- Located in War Room Command Center as a `ReplayControlTile`.
- Includes date selector, status feedback, and safe degradation.

## 2. Implementation
### Backend
- **Endpoint:** `POST /lab/replay/day` (Stub) in `backend/api_server.py`.
- **Response:** `{"status": "UNAVAILABLE", "reason": "REPLAY_ENDPOINT_MISSING", ...}` (Safe Stub).

### Frontend
- **Widget:** `ReplayControlTile` (`market_sniper_app/lib/widgets/war_room/replay_control_tile.dart`).
- **Wiring:** Integrated into `WarRoomScreen` grid.
- **Logic:** Handles `READY`, `RUNNING`, `SUCCESS`, `FAILED`, `UNAVAILABLE` states.

## 3. Verification
- **Preflight:** Git clean.
- **Analysis:** `flutter analyze` completed (existing issues baseline).
- **Wiring:** Tile successfully integrated into grid between ReplayIntegrity and LockReason.

## 4. Manifest
- `backend/api_server.py`
- `market_sniper_app/lib/widgets/war_room/replay_control_tile.dart`
- `market_sniper_app/lib/screens/war_room_screen.dart`
- `outputs/proofs/day_41/ui_replay_day_surface_proof.json`

## 5. Next Steps
- Implement actual `IronOS.run_replay_day()` engine logic (D41.04/05).
- Wire endpoint to real engine.
