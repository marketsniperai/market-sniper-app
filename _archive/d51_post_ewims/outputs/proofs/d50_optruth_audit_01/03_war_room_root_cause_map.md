# D50 War Room Root Cause Map

**Date:** 2026-01-29
**Audit:** D50.OPTRUTH.AUDIT.01

## 1. War Room Dashboard Crash (Critical)
**Symptom:** `GET /lab/war_room` returns `500 Internal Server Error` (or client error in script).
**Traceback:** `AttributeError: type object 'Housekeeper' has no attribute 'scan'`
**Location:** `backend/os_ops/war_room.py:35`
**Root Cause:**
- `WarRoom` calls `Housekeeper.scan()`.
- `Housekeeper` class (`backend/os_ops/housekeeper.py`) **does not implement** `scan()`.
- Likely regression or unfinished refactor from Day 42.
**Fix:** Update `WarRoom` to read `Housekeeper` status from its proof artifact (`outputs/proofs/day_42/day_42_03_housekeeper_auto_proof.json`) instead of calling a method.

## 2. Iron OS State History Unavailable
**Symptom:** `GET /lab/os/iron/state_history` returns `404 Not Found`.
**Location:** `backend/os_ops/iron_os.py:197`
**Root Cause:**
- Endpoint reads `outputs/os/os_state_history.json`.
- Artifact **does not exist**.
- No active writer identified for this specific JSON file (likely deprecated in favor of `os_timeline.jsonl`).
**Fix:**
- Immediate: Update `IronOS.get_state_history` to return an empty safe stub or derive from `os_timeline.jsonl`.
- Long-term: Implement dedicated history writer or deprecate endpoint.

## 3. Iron OS Drift Unavailable
**Symptom:** `GET /lab/os/iron/drift` returns `404 Not Found`.
**Location:** `backend/os_ops/iron_os.py:316`
**Root Cause:**
- Reads `outputs/os/os_drift_report.json`.
- Artifact **does not exist**.
- Drift engine likely not running or not persisting to this path.
**Fix:** Ensure Drift Engine runs or stub endpoint to N/A.

## 4. Canon Debt Radar Unavailable
**Symptom:** War Room UI shows "Canon Debt Radar: Unavailable".
**Root Cause:**
- `outputs/os/canon_debt_radar.json` is missing.
- No generator identified in `backend/os_ops`.
**Fix:** Mark as "Planned / Not Implemented" or create stub generator.

## 5. Elite Chat Connection
**Symptom:** Frontend reports "Connection Failed" if backend crashes.
**Status:** Audit shows `/elite/chat` returns 200 OK when backend is running.
**Conclusion:** Issues seen by user were likely due to the SyntaxError (Triple Quote) preventing backend startup.
**Fix:** The SyntaxError fix applied in `Step 2041` should resolve this.
