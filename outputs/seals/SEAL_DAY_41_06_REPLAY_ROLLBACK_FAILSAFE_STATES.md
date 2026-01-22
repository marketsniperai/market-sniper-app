# SEAL: D41.06 - Replay/Rollback Failsafe & Integrity (OS.R2.2)

> [!IMPORTANT]
> **Status:** SEALED
> **Date:** 2026-01-22
> **Author:** ANTIGRAVITY

## 1. Feature
**Failsafe States & Integrity Indicators**
- **Safety First:** Explicit integrity checks (Replay/Iron Hash) run before allowing playback.
- **Visual Feedback:** "INT: OK" or "INT: RISK" badge displayed on the Replay/Rollback UI.
- **Hard Gate:** Execution prevented if integrity is compromised (`INTEGRITY_RISK`).

## 2. Implementation
### Frontend
- **Fetcher:** `_fetchIntegrity()` checks `/lab/os/iron/replay_integrity`.
- **States:** Added `_integritySafe` logic mapping `corrupted`/`truncated` flags to risk state.
- **UI:** Added boxed integrity badge to `ReplayControlTile` footer.
- **Guard:** `_runReplay` checks `_integritySafe` before execution.

## 3. Verification
- **Network:** Stub endpoint response parsed correctly.
- **States:** `OK`, `RISK`, `UNKNOWN` states rendered.
- **Blocking:** Risk state successfully blocks run action.

## 4. Manifest
- `market_sniper_app/lib/widgets/war_room/replay_control_tile.dart` (Updates)
- `outputs/proofs/day_41/ui_replay_rollback_failsafe_states_proof.json`

## 5. Next Steps
- D41.05: Founder-Gated Rollback UI (Now safe to implement).
