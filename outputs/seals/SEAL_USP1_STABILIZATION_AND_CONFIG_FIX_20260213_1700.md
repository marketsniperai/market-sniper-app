# SEAL: USP-1 STABILIZATION & WAR ROOM CONFIG FIX
**Date:** 2026-02-13
**Subject:** Stabilization of Snapshot Protocol and Feature Flag Source of Truth

## 1. Backend Stabilization (Objective A)
- **Problem**: Snapshot endpoint could return 404/500 if output directory missing or write failed.
- **Fix Applied**: `backend/api_server.py`
    - Added `os.makedirs(target_dir, exist_ok=True)` before writing.
    - Wrapped execution in `try-except` block.
    - **Outcome**: Returns `200 OK` with `status="COMPUTE_ERROR"` on failure, never 404.

## 2. Frontend Source of Truth (Objective B)
- **Problem**: `WAR_ROOM_ACTIVE` might not reflect `--dart-define` if initialized incorrectly.
- **Fix Applied**: `lib/config/app_config.dart`
    - Logic: `static bool _warRoomActive = const bool.fromEnvironment(...)`
    - Logging: Added `TRUTH_PROBE: WAR_ROOM_ACTIVE = ... (SOURCE: fromEnvironment)` to startup logs.

## 3. Proof of Stabilization
- **Curl Test**: `curl ... /lab/war_room/snapshot` -> `200 OK` (Verified).
- **Log Probe**:
  ```text
  TRUTH_PROBE: WAR_ROOM_ACTIVE = true (SOURCE: fromEnvironment)
  ```

**Verdict**: STABILIZED. 200 ALWAYS. TRUTH VISIBLE.
