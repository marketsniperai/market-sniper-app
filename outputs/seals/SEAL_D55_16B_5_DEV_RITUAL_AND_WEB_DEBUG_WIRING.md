# SEAL: D55.16B.5 — DEV RITUAL RESTORE + WEB DEBUG WIRING

**Date:** 2026-02-05
**Author:** Antigravity (Agent)
**Status:** SEALED
**Classification:** INFRASTRUCTURE FIX

## 1. Context
The local development "Pulse Check" ritual (`tools/dev_ritual.ps1`) was broken because it referenced a non-existent proxy (`tools/dev_proxy/proxy.py`). This caused the backend to never start. Additionally, `AppConfig.dart` was hardcoded to expect this proxy on port 8787 for Web Debug builds, resulting in "Connection Refused" (404-like behavior) for all War Room tiles locally.

## 2. Actions Taken
- **Infrastructure Repair**: Modified `tools/dev_ritual.ps1` to remove the dead proxy reference and instead launch the canonical backend (`backend/api_server.py`) directly on port 8000 using `uvicorn`.
- **Frontend Wiring**: Updated `market_sniper_app/lib/config/app_config.dart` to target `http://localhost:8000` (Direct Backend) when in `kIsWeb && kDebugMode`. Production configuration was untouched.
- **Hygiene**: Ensured `FOUNDER_KEY` is passed via secure environment variable injection, not CLI arguments.

## 3. Verification Results
| Check | Command | Expected | Result |
| :--- | :--- | :--- | :--- |
| **Backend Liveness** | `curl http://localhost:8000/health_ext` | 200 OK | **PASS** |
| **Founder Access** | `curl -H "X-Founder-Key: TEST..." ...` | 200 OK | **PASS** |
| **Hostile Access** | `curl http://localhost:8000/lab/war_room` | 403 Forbidden | **PASS** |
| **Integrity** | `flutter analyze` | No Errors | **PASS** (223 baseline issues) |

## 4. Artifacts
- **Modified**: `tools/dev_ritual.ps1`
- **Modified**: `market_sniper_app/lib/config/app_config.dart`
- **Updated**: `PROJECT_STATE.md`, `OMSR_WAR_CALENDAR`

## 5. Next Steps
- Verify visual War Room behavior in Chrome (Manual).
- Continue with D55.16B verification series if needed.

## Pending Closure Hook
- Resolved Pending Items:
  - None
- New Pending Items:
  - None

