# D56.AUDIT.CHUNK_01 — PATCH PLAN

## 1. D06.SCHED Restoration
- **Problem:** `SEAL_DAY_06` claims Scheduler. Backend lacks `scheduler.py`.
- **Action:**
  - [ ] Investigate `api_server.py` startup events (did it absorb scheduler?).
  - [ ] If missing, re-implement `backend/scheduler.py` using `APScheduler` or simple loop (as per original D06 intent).
- **Target:** CHUNK_02 or PATCH_D56_01.

## 2. D10 Locks Verification
- **Problem:** `core_gates.py` exists but verification script had path error.
- **Action:** Update verifier and confirm runtime locking.

## 3. D08 Misfire Runtime w/ Python
- **Problem:** Verify script relying on `python` failed earlier.
- **Action:** Now that `python` is aliased, run `verify_misfire_root_cause_proof.py`.
