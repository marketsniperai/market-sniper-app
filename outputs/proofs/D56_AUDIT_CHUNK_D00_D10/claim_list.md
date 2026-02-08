# D56.AUDIT.CHUNK_01 — CLAIM LIST (D00-D10)

**Chunk:** D00 - D10
**Status:** VERIFIED

| Claim ID | Seal / Milestone | Primary Assertions | Expected Evidence | Status |
| :--- | :--- | :--- | :--- | :--- |
| **D00.SHELL** | `SEAL_DAY_00_5_FLUTTER_SHELL.md` | Flutter Shell exists and compiles. | Code: `lib/main.dart` | **GREEN** (Verified) |
| **D04.PIPE** | `SEAL_DAY_04_PIPELINE_MIN_REAL.md` | Pipeline Controller exists. | Code: `backend/pipeline_controller.py` | **YELLOW** (Code Exists) |
| **D06.SCHED** | `SEAL_DAY_06_2_PIPELINE_HYDRATION_AND_SCHEDULER.md` | Scheduler logic exists. | Code: `backend/scheduler.py` | **GHOST** (Missing) |
| **D06.GCS** | `SEAL_DAY_06_3_GCSFUSE_PERSISTENCE` | GCSFuse persistence logic. | Code: `backend/artifacts/io.py` | **YELLOW** (Code Exists) |
| **D08.MISFIRE** | `SEAL_DAY_08_MISFIRE_MONITOR` | Misfire Monitor exists. | Code: `backend/os_ops/misfire_monitor.py` | **YELLOW** (Code Exists) |
| **D10.LOCKS** | `SEAL_DAY_10_DUAL_PIPELINE_LOCKS` | Pipeline Locks / Cooldowns. | Code: `backend/gates/core_gates.py` | **YELLOW** (Code Exists) |
| **D00.TRUTH** | `SEAL_DAY_00_3_TRUTH_SURFACE.md` | Truth Surface (Artifacts). | Dir: `outputs/` | **GREEN** (Verified) |
