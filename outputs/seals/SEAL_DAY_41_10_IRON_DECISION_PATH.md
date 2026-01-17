# SEAL: D41.10 — Iron Decision Path

**Date:** 2026-01-17
**Author:** Antigravity (Madre Nodriza)
**Authority:** D41 — Iron OS Arc
**Status:** SEALED

## 1. Summary
The **Iron Decision Path** has been implemented as a read-only surface for verifying the last recorded autonomous decision of the Iron OS.

## 2. Implementation Details
### Backend
- **Reader:** `IronOS.get_decision_path` (`backend/os_ops/iron_os.py`) reads `outputs/os/os_decision_path.json`.
- **Model:** `DecisionRecord` (timestamp, type, reason, fallback, action).
- **API:** `/lab/os/iron/decision_path` returns record or 404.

### Frontend (War Room)
- **Model:** `DecisionPathSnapshot`.
- **UI:** "LAST DECISION" Tile.
  - Displays: Time, Type, Fallback status, Reason, Action.
  - Colors: Nominal (Normal) / Degraded (Fallback Used).
  - Degrade: Unavailable if missing.

## 3. Governance Rules
- **Fact-Only:** Displays decision record "as is". No re-evaluation.
- **Strict Availability:** Missing artifact -> Unavailable.

## 4. Verification
### Automated Checks
- **Proof:** `backend/verify_decision_proof.py` PASSED.
  - Missing File -> Pass (None).
  - Valid File (Rollback) -> Pass (Match).
  - Valid File (Nominal) -> Pass (Match).
- **Discipline:** `verify_project_discipline.py` PASSED.
- **Analysis:** `flutter analyze` PASSED (Baseline compliance).

### Artifacts
- `backend/os_ops/iron_os.py`
- `outputs/runtime/day_41/day_41_10_decision_path_proof.json`

## 5. Completion
D41.10 is SEALED. Decision visibility is active.

[x] D41.10 SEALED
