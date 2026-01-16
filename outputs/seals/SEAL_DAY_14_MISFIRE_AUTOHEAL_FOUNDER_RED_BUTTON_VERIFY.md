# SEAL: DAY 14 - MISFIRE + AUTOHEAL + RED BUTTON

## Status
**VERIFIED** -> **FAIL** (Overall)
**SYSTEM HEALTH** -> **NOMINAL** (Manually Restored)

## Components Verified
1. **Misfire Monitor**: **PASS**. Detected `MISSING_ARTIFACT` correctly during force test. Persisted report atomically.
2. **Autoheal Trigger**: **PARTIAL**. `/lab/misfire_autoheal` endpoint triggered the Cloud Run Job.
3. **Red Button Execution**: **FAIL**. The triggered job crashed immediately.

## Failure Analysis
- **Symptom**: Cloud Run Job `market-sniper-pipeline-x9bk8` exited with code 2.
- **Root Cause**: Invalid arguments passed to container.
  - Log: `textPayload: unknown option --mode`
  - Log: `textPayload: usage: /usr/local/bin/python ...`
  - Reason: The `trigger_autoheal` function overrides `args` with `["--mode", "FULL"]`. If the container Entrypoint is `python`, this results in `python --mode FULL`, which is invalid because the script filename is missing.
- **Impact**: The system detects misfire but cannot auto-heal. Founder intervention is required (manual pipeline run).

## Manual Recovery
- **Action**: Renamed `full/run_manifest.json.bak` back to `full/run_manifest.json` via `gsutil`.
- **Result**: `/misfire` endpoint now returns `NOMINAL`. System is healthy but Autoheal is broken.

## Top 5 Fixes (Required for PASS)
1.  **Fix Argument Override**: In `backend/misfire_monitor.py`, update `args` to include the script name: `["pipeline_job.py", "--mode", "FULL"]` (or whatever the entrypoint script is named).
2.  **Verify Job Definition**: Check if the Cloud Run Job definition uses `command` vs `args` to ensure overrides align.
3.  **Add Container Logic**: Alternatively, update the container entrypoint to handle generic args if possible.
4.  **Logging**: Improve the API response to include the Job UID for easier tracing (already partial, but explicit link would be better).
5.  **Retry Verification**: Re-run the full Day 14 verification suite after applying Fix 1.

## Statement
The Day 14 milestone is **NOT** met. The "Red Button" creates a broken job execution. However, monitoring and manual/nominal operations are functional.
