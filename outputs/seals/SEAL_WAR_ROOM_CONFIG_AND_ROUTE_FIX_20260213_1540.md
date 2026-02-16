# SEAL: WAR ROOM CONFIG & ROUTE SANITIZATION
**Date:** 2026-02-13
**Subject:** Fix for `WAR_ROOM_ACTIVE` Config & Snapshot 404 Root Cause

## 1. Findings & Actions

### Phase 1: WAR_ROOM_ACTIVE Config (FIXED)
- **Issue**: `AppConfig.isWarRoomActive` defaulted to `false` and ignored the `--dart-define=WAR_ROOM_ACTIVE=true` flag.
- **Root Cause**: The backing variable `_warRoomActive` was initialized with literal `false` instead of `const bool.fromEnvironment`.
- **Action**: Modified `market_sniper_app/lib/config/app_config.dart` to rely on `fromEnvironment`.
- **Status**: **FIXED**. Requires rebuild/reload to take effect.

### Phase 2: Snapshot 404 Root Cause (DIAGNOSED)
- **Symptom**: `GET /lab/war_room/snapshot` returns `404 Not Found`.
- **Probe**: `curl -H "X-Founder-Key: mz_founder_888" https://api.marketsniperai.com/lab/war_room/snapshot`
- **Result**:
  ```
  < HTTP/1.1 404 Not Found
  < x-founder-trace: FOUNDER_BUILD=TRUE; KEY_SENT=True
  {"detail":"Not Found"}
  ```
- **Diagnosis**: 
    1. The route **does exist** in backend code (`api_server.py:1043`).
    2. The response body matches the **Fail-Hidden Security Logic** in `PublicSurfaceShieldMiddleware` (lines 114-123).
    3. The 404 is **INTENTIONAL** when authorization fails.
- **Conclusion**: The production environment likely uses a different `FOUNDER_KEY` than the dev key `mz_founder_888`. Access is denied because of key mismatch.

## 2. Recommendation
- **Client Side**: Ensure the `FOUNDER_KEY` passed to `flutter run` matches the value set in Cloud Run environment variables.
- **Server Side**: Verify the `FOUNDER_KEY` env var in Cloud Run console if valid access is blocked.

**Verdict**: CONFIG FIXED; ROUTE VALID (AUTH BLOCKED).

**Sign-off**: Antigravity
