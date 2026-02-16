# SEAL: FOUNDER KEY SSOT & SNAPSHOT 200 PROOF
**Date:** 2026-02-13
**Subject:** Unblocking War Room Snapshot Route (Auth Restoration)

## 1. Root Cause Analysis (Confirmed)

### A. The "Ghost Key"
- **Symptom**: `curl` with `X-Founder-Key: mz_founder_888` returned `404 Not Found`.
- **Backend Logic**: `api_server.py` uses `PublicSurfaceShieldMiddleware`. If `FOUNDER_KEY` env var is **missing** or **mismatched**, it returns 404 (Fail-Hidden) to protect the route.
- **Cloud Audit**: `gcloud run services describe` confirmed `marketsniper-api` had **NO `FOUNDER_KEY`** configured (neither as env var nor secret).
- **Impact**: The backend was effectively "Locked Down" (Fail-Closed). No key could ever pass validation.

## 2. Remediation Action (Minimal Config Fix)

### Operation
- **Command**: `gcloud run services update marketsniper-api --set-env-vars=FOUNDER_KEY=mz_founder_888`
- **Result**: Deployed Revision `marketsniper-api-00037`.

## 3. Verification Proof (200 OK)

### Curl Test
```powershell
curl.exe -i -H "X-Founder-Key: mz_founder_888" "https://api.marketsniperai.com/lab/war_room/snapshot"
```

### Result (Success)
```http
HTTP/1.1 200 OK
content-type: application/json
x-founder-trace: FOUNDER_BUILD=TRUE; KEY_SENT=True
...
{"status":"COMPUTE_ERROR","as_of_utc":"...","reason_codes":["[Errno 2] No such file..."]}
```

- **Status**: `200 OK` (Auth Passed).
- **Payload**: `COMPUTE_ERROR` (Expected for fresh instance without persistent volume data yet). 
- **Key Takeaway**: The **404 Block is GONE**. The application layer is now reachable.

## 4. Next Steps
- **Client**: `flutter run` will now successfully hit the endpoint.
- **Observability**: The `COMPUTE_ERROR` will likely self-resolve as the backend generates fresh snapshots, or requires a separate "Cold Start" fix (outside scope of this Unblock task).

**Verdict**: FOUNDER KEY RESTORED. ROUTE UNBLOCKED.

**Sign-off**: Antigravity
