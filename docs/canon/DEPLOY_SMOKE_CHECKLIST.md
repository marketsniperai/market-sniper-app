# DEPLOYMENT SMOKE TEST CHECKLIST (D56.01.10)

**Date:** 2026-02-05
**Scope:** Post-Deployment Verification for Cloud Run (or any Prod Environment).
**Mandate:** NO DEPLOYMENT IS COMPLETE UNLESS THE SMOKE TEST PASSES.
**Critical Update:** Root probes (`/healthz`) are unreliable due to Edge 404. Use `/lab/*` probes.

## 1. Prerequisites
- **Procfile**: MUST be present (`web: python -m backend.api_server`).
- **Region**: `us-central1`.
- **Auth**: `FOUNDER_KEY` set (Env or Secret).

## 2. Automated Verification (Preferred)

After deploying to Cloud Run, execute one of the following scripts from your local machine or CI pipeline.

### Option A: PowerShell (Windows/CI)
```powershell
$env:CLOUD_RUN_URL="https://your-service-url.a.run.app"
$env:FOUNDER_KEY="your-secret-key"
./tools/smoke_cloud_run.ps1
```

### Option B: Bash (Linux/Mac/Cloud Shell)
```bash
export CLOUD_RUN_URL="https://your-service-url.a.run.app"
export FOUNDER_KEY="your-secret-key"
./tools/smoke_cloud_run.sh
```

## 3. Expected Output
A successful run MUST end with `exit code 0` and display:
```
[PASS] /lab/healthz -> 200
[PASS] /lab/readyz -> 200
[PASS] Snapshot checks...
✅ SMOKE TEST PASSED
```

## 4. Manual Fallback (If scripts fail)

If automation fails, verify manually to diagnose:

1.  **Health Check (Lab Probe)**:
    `curl https://TARGET_URL/lab/healthz`
    *Expected*: `{"status": "ALIVE", "mode": "PROD"}`

2.  **Readiness (Lab Probe)**:
    `curl https://TARGET_URL/lab/readyz`
    *Expected*: `{"status": "READY", "mode": "PROD"}`

3.  **Auth Shield**:
    `curl https://TARGET_URL/lab/war_room/snapshot`
    *Expected*: `403 Forbidden`

4.  **Deep Verify (Auth)**:
    `curl -H "X-Founder-Key: SECRET" https://TARGET_URL/lab/war_room/snapshot`
    *Expected*:
    - Status: 200
    - `meta.contract_version`: "USP-1"
    - `meta.missing_modules`: `[]` (Empty)
    - `modules` contains keys: `autopilot`, `housekeeper`, `misfire`, `iron_os`, `canon_debt_radar`, etc.

## 5. Troubleshooting
- **404 on Probes**: Ensure you are checking `/lab/healthz` not `/healthz`.
- **403 Forbidden**: Check `FOUNDER_KEY` matches environment variable.
- **Connection Refused**: Check if `Procfile` exists and `PORT` binding is correct.
- **500 Error**: Check logs for "Missing Module" or "Import Error".
- **Missing Modules**: Check `backend/os_ops/war_room.py` and `war_room_contract.py` sync.
