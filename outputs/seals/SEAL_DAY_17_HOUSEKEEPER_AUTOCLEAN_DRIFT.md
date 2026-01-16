# SEAL: DAY 17 - HOUSEKEEPER AUTO + AUTOCLEAN + DRIFT CLEANUP

**Date**: 2026-01-14
**Author**: Antigravity (OMSR)
**Status**: PASS

## 1. Objective
Implement the "Housekeeper" system to automatically manage operational entropy (garbage files, orphan locks) and detect configuration drift, ensuring the OS remains healthy without manual intervention.

## 2. Implementation Truth
### Module: `backend/housekeeper.py`
- **Scan**: Recursive scan of `outputs/`.
    - Identifies `.tmp`, `.bak` files.
    - Identifies `os_lock.json`.
- **Classify**:
    - `SAFE_TO_CLEAN`: Items > 1 hour old.
    - `RECENT_TEMP`: Items < 1 hour old (Protected).
    - `PROTECTED`: All other files (manifests, reports, etc.).
- **Drift**: Checks for existence of critical manifests (`full/run_manifest.json`, `light/run_manifest.json`).
- **Execute**:
    - Deletes items marked `SAFE_TO_CLEAN`.
    - Appends purge details to `housekeeper_ledger.jsonl`.
    - Protected by `X-Founder-Key`.

### Endpoints (in `backend/api_server.py`)
- `GET /housekeeper`: Dry-run Scan. Returns status `CLEAN`, `GARBAGE_FOUND`, or `DRIFT_DETECTED`.
- `POST /lab/housekeeper/run`: Executes cleanup.

## 3. Verification Results

| Test | Expectation | Result | Note |
|---|---|---|---|
| **Baseline** | Status `CLEAN` | **PASS** | `day_17_baseline.txt` |
| **Forced Garbage** | `GARBAGE_FOUND` | **PASS** | Identified old tmp and stuck lock correctly. |
| **Protection** | Recent tmp NOT deleted | **PASS** | `recent_17.tmp` preserved. |
| **Cleanup** | Old tmp/lock DELETED | **PASS** | `day_17_execute_clean.txt` |
| **Drift** | `DRIFT_DETECTED` (Missing Manifest) | **PASS** | `day_17_drift_detection.txt` |
| **Ledger** | Entry recorded | **PASS** | `day_17_ledger_tail.txt` |

## 4. Governance Note
> [!IMPORTANT]
> **Safety First**: The Housekeeper defaults to Scan-Only. Execution is strictly Founder-Gated and respects a logic safety buffer (1 hour minimum age for trash).
> **Drift Awareness**: The system now self-reports when its runtime state (Manifests) deviates from expectation.

## 5. Next Steps
- Day 18: Operational Dashboard (Aggregating AutoFix + Housekeeper + Misfire).
