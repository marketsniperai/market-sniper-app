# SEAL: D56.01.8 - CLOUD RUN / PROD HARDENING (DEPLOY-PROOF WAR ROOM)

**Date:** 2026-02-05
**Author:** Antigravity (Agent)
**Scope:** Backend Hardening, Port Binding, Health Checks, Structured Logging, Config Centralization.

## 1. Problem Statement
The legacy backend was fragile for production deployments:
- Hardcoded port 8000 (failed in Cloud Run which injects `$PORT`).
- Non-standard/Scattershot configuration (`os.getenv` everywhere).
- Missing Liveness/Readiness probes (`/healthz`).
- Ambiguous logging (no request ID, secret leakage risk).
- Potentially unsafe default binding (`127.0.0.1` vs `0.0.0.0`).

## 2. Solution Implemented
### A. Centralized Configuration
- Created `backend/config.py`:
  - `HOST`: Defaults to `0.0.0.0` (Container Standard).
  - `PORT`: Defaults to `8000`, respects inputs (Cloud Run Standard).
  - `SYSTEM_MODE`: `PROD` vs `LAB`.

### B. Backend Hardening (`api_server.py`)
- **Port Binding**: Uses `BackendConfig.PORT` in `uvicorn.run`.
- **Health Probes**:
  - `GET /healthz`: Returns 200 `ALIVE`.
  - `GET /readyz`: Returns 200 `READY` (checks Artifacts Root).
- **Observability**: Added `RequestObservabilityMiddleware`:
  - Logs structured JSON (ts, req_id, path, status, latency).
  - Skips noise for health checks.
- **Safety**: `PublicSurfaceShieldMiddleware` now centralized via Config.

### C. Frontend Verification
- Verified `AppConfig.dart` ensures `API_BASE_URL` (Dart Define) takes precedence over all else.

## 3. Verification Proofs (Local Simulation)
**Scenario**: `PORT=8081`, `SYSTEM_MODE=PROD`, `FOUNDER_KEY=cloud_run_test_key`.

| Check | Payload/Header | Result | Status |
|:---|:---|:---|:---|
| **Liveness** | `GET /healthz` | `{"status":"ALIVE","mode":"PROD"}` | [x] PASS |
| **Readiness** | `GET /readyz` | `{"status":"READY","mode":"PROD"}` | [x] PASS |
| **Auth Shield** | `GET /lab/war_room/snapshot` (No Key) | HTTP 403 Forbidden | [x] PASS |
| **Auth Access** | `header: X-Founder-Key: cloud_run_test_key` | HTTP 200 OK | [x] PASS |

**Log Proof**:
```json
{"ts": "2026-02-05T...", "lvl": "INFO", "req_id": "...", "path": "/lab/war_room/snapshot", "status": 200, "lat_ms": 31, "mode": "PROD"}
```

## 4. Manifest
- [NEW] `backend/config.py`
- [MOD] `backend/api_server.py`
- [VERIFIED] `market_sniper_app/lib/config/app_config.dart`

## 5. Verdict
**STATUS: SEALED (HARDENED)**
The backend is now compliant with Cloud Run constraints (Port Injection, Health Checks) and provides the necessary observability for production diagnostics. "It works on my machine" is dead; "It works on Config" is the new law.
