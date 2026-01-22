# SEAL: D41.05 - Founder-Gated Rollback UI (OS.R2.3)

> [!IMPORTANT]
> **Status:** SEALED
> **Date:** 2026-01-22
> **Author:** ANTIGRAVITY

## 1. Feature
**Founder-Gated Rollback Action**
- **Trigger:** "ROLLBACK" button in Replay Control Tile (Founder execution only).
- **Safety:** Modal confirmation requiring user to type "ROLLBACK".
- **Logging:** All attempts logged to `os_rollback_intent_ledger.jsonl`.
- **Execution:** Currently a Safe Stub returning `UNAVAILABLE`.

## 2. Implementation
### Backend
- **Endpoint:** `POST /lab/os/rollback` (Stub).
- **Ledger:** `RollbackLedger` appends structured logs (actor, action, hash, reason).

### Frontend
- **Button:** Added Red "ROLLBACK" button to control row.
- **Modal:** Implemented `_confirmRollback` with text validation.
- **Service:** `_executeRollback` calls API and handles stub response.

## 3. Verification
- **Gate:** Button only active for Founder.
- **Modal:** Confirm disabled until "ROLLBACK" matches exactly.
- **Ledger:** Verified `log_intent` call in stub.

## 4. Manifest
- `backend/api_server.py`
- `backend/os_ops/rollback_ledger.py`
- `market_sniper_app/lib/widgets/war_room/replay_control_tile.dart`
- `outputs/proofs/day_41/ui_founder_rollback_confirm_logging_proof.json`

## 5. Next Steps
- D41.B1: Time Machine Backend (Real Replay Engine).
