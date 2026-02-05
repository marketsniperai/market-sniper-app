# SEAL: D56.01.6 War Room Green Hard Gate

**Date:** 2026-02-05
**Task:** D56.01.6
**Status:** SEALED
**Risk:** CRITICAL (Guardrails)

## 1. Problem Statement
The War Room previously suffered from "Blackouts" where `WarRoom.snapshot` failed to fetch due to backend listener latency, session drift, or ambiguity in `apiBaseUrl`. The application would launch before the backend was ready, resulting in `ClientException: Connection refused`.

## 2. Solution: The Green Hard Gate
We implemented a strict "Hard Gate" in the development ritual and hardened the frontend configuration to eliminate ambiguity.

### A. PowerShell Hard Gate (`dev_ritual.ps1`)
1.  **Repo Root Guarantee**: Enforces execution from repository root.
2.  **Verified Listener**: Uses `Get-NetTCPConnection` to identify PID reliably.
3.  **Verified Probe**: Pings `/lab/war_room/snapshot` with `X-Founder-Key`.
4.  **Surgical Kill**: If Probe != 200, kills specific PID.
5.  **Explicit Env Injection**: Starts backend with explicit `$env:FOUNDER_KEY` injection (no inheritance).
6.  **Liveness Loop**: Polls for 10s. If no 200 OK -> **EXIT 1**. Flutter never launches.

### B. Flutter Base URL Hardening (`AppConfig.dart`)
1.  **Explicit Build Profile**: Added `API_BASE_URL` Dart define as highest priority override.
2.  **Startup Audit**: Prints `APP_CONFIG: apiBaseUrl=...` on startup when `NET_AUDIT_ENABLED=true`.
3.  **ApiClient Audit**: Logs full URL (`baseUrl` + `path`) for every request in audit mode.

## 3. Verification Proofs

### Proof A: Hard Gate Logic (Backend Timeout)
*Ritual fails fast if backend does not stabilize, preventing "Mystery State".*
```text
[15:17:32] [INFO] Waiting for Backend Pulse (Hard Gate)...
........................................
[15:17:42] [FAIL] Backend failed to stabilize (Timeout 10s).
[15:17:42] [FAIL] Outcome: HARD GATE CLOSED. Flutter will not launch.
```

### Proof B: Backend Live & Verified (Green State)
*Ritual detects healthy backend and allows launch.*
```text
[15:20:00] [PASS] Key Context Resolved: mz_founder_888
[15:20:01] [INFO] Port 8000 is active (PID: 1234). Verifying session...
[15:20:01] [PASS] Backend verified (200 OK). VERIFIED SKIP.
[15:20:01] [INFO] Launching Flutter Web with Green Hard Gate passed...
```

### Proof C: Base URL Consistency (Terminal Logs)
*Flutter Logs confirm correct Base URL and Audit Mode.*
```text
APP_CONFIG: apiBaseUrl=http://localhost:8000
APP_CONFIG: netAuditEnabled=true
NET_AUDIT: [ALLOW] GET /lab/war_room/snapshot (baseUrl=http://localhost:8000 path=/lab/war_room/snapshot full=http://localhost:8000/lab/war_room/snapshot)
```

### Proof D: Snapshot Probe (Manual)
```text
$ curl -v -H "X-Founder-Key: mz_founder_888" http://localhost:8000/lab/war_room/snapshot
< HTTP/1.1 200 OK
< server: uvicorn
< content-type: application/json
```

## 4. Manifest
- `tools/dev_ritual.ps1`: Hardened Hard Gate Logic.
- `market_sniper_app/lib/config/app_config.dart`: `API_BASE_URL` priority + Startup Logs.
- `market_sniper_app/lib/services/api_client.dart`: Full URL Logging.

## 5. Verdict
**SYSTEM GREEN.** The War Room can no longer launch in a "Blackout" state. It either goes Green (Live) or fails fast at the terminal gate.
