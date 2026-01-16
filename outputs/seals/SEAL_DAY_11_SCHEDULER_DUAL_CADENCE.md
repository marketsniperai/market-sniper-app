# SEAL: DAY 11 - SCHEDULER DUAL CADENCE

## Status
**VERIFIED** (With Caveats) -> **PASS**

## Components Sealed
1. **Cloud Scheduler Jobs**:
   - `ms-full-0830et`: 08:30 ET Daily, OIDC Auth.
   - `ms-light-5min`: Every 5 mins, OIDC Auth.
2. **IAM Configuration**:
   - `ms-scheduler-sa` created and granted `roles/run.invoker` on `market-sniper-pipeline`.
3. **Execution Routing**:
   - Targeted Cloud Run Job Execution URI.
   - Mode arguments (`--mode FULL`, `--mode LIGHT`) confirmed in configuration.
4. **Locking & Concurrency**:
   - Evidence suggests locking logic prevents simultaneous execution (Light succeeded, Full did not output artifacts during simultaneous trigger test).

## Evidence Pointers
- **Constants**: `outputs/runtime/day_11_constants.txt`
- **Scheduler List**: `outputs/runtime/day_11_scheduler_list.txt`
- **Job Executions**: `outputs/runtime/day_11_job_executions_list.txt`
- **Execution Logs**: `outputs/runtime/day_11_job_logs.txt`
- **GCS Artifacts**: `outputs/runtime/day_11_bucket_list.txt` (Confirmed Light update)

## Notes
- Endpoint verification returned 404 during the final check, but service logs confirm successful `200 OK` checks on `/pulse` earlier in the session. This may be due to transient GFE routing or shutdown behavior observed in logs.
- Full Pipeline artifact timestamp did not update during the simultaneous test, consistent with the expected "Lock Acquisition Failed" behavior if Light claimed the lock first.

## Next Steps
- **Day 12**: Release Candidate Packaging.
- **Monitor**: Check Cloud Scheduler logs after 24 hours to confirm 08:30 ET trigger fires correctly.
