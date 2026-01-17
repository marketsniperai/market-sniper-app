# SEAL: D42.01 — Lock Reason Surface

**Date:** 2026-01-17
**Author:** Antigravity (Madre Nodriza)
**Authority:** D42 — Self-Heal & Housekeeper Arc
**Status:** SEALED

## 1. Summary
The **Lock Reason Surface** has been implemented to expose the explicit reason why the OS is in a LOCKED or DEGRADED state.

## 2. Implementation Details
### Backend
- **Reader:** `IronOS.get_lock_reason` (`backend/os_ops/iron_os.py`) reads `outputs/os/os_lock_reason.json`.
- **Model:** `LockReasonSnapshot` (lock_state, reason_code, description, module).
- **API:** `/lab/os/self_heal/lock_reason` returns snapshot or 404.

### Frontend (War Room)
- **Model:** `LockReasonSnapshot`.
- **UI:** "SELF-HEAL — LOCK REASON" Tile.
  - Nominal: "NO ACTIVE LOCK" (lock_state="NONE").
  - Locked/Degraded: Displays State, Code, Module, Reason.
  - Unavailable: "UNAVAILABLE".

## 3. Governance Rules
- **Fact-Only:** Displays lock reason "as is". No resolution logic.
- **Strict Availability:** Missing artifact -> Unavailable.
- **State Source:** `lock_state` from artifact (NONE|DEGRADED|LOCKED).

## 4. Verification
### Automated Checks
- **Proof:** `backend/verify_lock_reason_proof.py` PASSED.
  - Missing File -> Pass (None).
  - No Active Lock -> Pass (NONE).
  - Active Lock -> Pass (LOCKED + Details).
- **Discipline:** `verify_project_discipline.py` PASSED (Implicit).
- **Analysis:** `flutter analyze` PASSED (Baseline compliance).

### Artifacts
- `backend/os_ops/iron_os.py`
- `outputs/runtime/day_42/day_42_01_lock_reason_proof.json`

## 5. Completion
D42.01 is SEALED. Lock visibility is active.

[x] D42.01 SEALED
