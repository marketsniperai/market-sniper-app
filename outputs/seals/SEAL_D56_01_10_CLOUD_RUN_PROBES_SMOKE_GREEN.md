# SEAL: D56.01.10 - CLOUD RUN DEPLOY + PROBE FIX + SMOKE AUDIT

**Date:** 2026-02-05
**Author:** Antigravity (Agent)
**Scope:** Cloud Run Deployment, Probe Fix (Edge 404 Bypass), Final Smoke Test Verification.

## 1. Problem Statement
The Cloud Run "Edge" (Google Frontend) intercepts `/healthz` and `/readyz` paths when the user is unauthenticated, often returning 404 HTML before the request hits the container, breaking automated smoke tests.
Additionally, the initial deployment failed due to missing Entrypoint (Fixed with `Procfile`).

## 2. Solution Implemented
### A. LAB Probes (Edge Bypass)
Moved probes to:
- `GET /lab/healthz` -> 200 ALIVE
- `GET /lab/readyz` -> 200 READY
Updated `PublicSurfaceShieldMiddleware` to allowlist these paths. This guarantees the probe reaches the container application logic.

### B. Deployment Hardening
- **Procfile**: Added `web: python -m backend.api_server` to ensure correct startup.
- **Config**: `SYSTEM_MODE=PROD`, `FOUNDER_KEY` set via Env.
- **Allow Unauthenticated**: Enabled for Service (Shield protects sensitive routes).

### C. Guardrail Update
Updated `tools/smoke_cloud_run.ps1` and `.sh` to check `/lab/healthz` and `/lab/readyz`, enforcing the "Probe Reachability" requirement.

## 3. Verification Proofs (Real Cloud Run URL)
**Target:** `https://marketsniper-api-3ygzdvszba-uc.a.run.app`

### Gate A: Manual Curl Proofs
**Liveness (Lab Probe)**
```
HTTP/1.1 200 OK
content-type: application/json
server: uvicorn

{"status":"ALIVE","mode":"PROD"}
```

**Readiness (Lab Probe)**
```
HTTP/1.1 200 OK
content-type: application/json

{"status":"READY","mode":"PROD"}
```

**Shield (Unauthorized)**
```
HTTP/1.1 403 Forbidden
content-type: application/json

{"detail":"Forbidden: Shield Active (Cloud Run Hardened)"}
```

**Snapshot (Authorized)**
```
HTTP/1.1 200 OK
content-type: application/json
x-founder-trace: MODE=PROD; KEY_SENT=True

{"meta":{"contract_version":"USP-1", ... "missing_modules":[] ... }
```

### Gate B: Automated Smoke Test
```
[PASS] /lab/healthz JSON payload OK
[PASS] /lab/readyz JSON payload OK
[PASS] GET /lab/war_room/snapshot (No Key) -> 403 Forbidden
[PASS] Snapshot Meta Checks (USP-1, Empty Missing Modules)
[PASS] Module Keys Count (21) >= 21
✅ SMOKE TEST PASSED
```

## 4. Manifest
- [NEW] `Procfile`
- [DTX] `backend/api_server.py` (Added Lab Probes)
- [MOD] `tools/smoke_cloud_run.ps1` (Probe Paths)
- [MOD] `tools/smoke_cloud_run.sh` (Probe Paths)

## 5. Verdict
**STATUS: SEALED (GREEN)**
The deployment is robust. Probes are reachable, Shield is active, Data is hydrated, and automated Smoke Tests passed against the live production environment.

## Pending Closure Hook
- Resolved Pending Items:
  - None (Legacy Seal Retrofit)
- New Pending Items:
  - None
