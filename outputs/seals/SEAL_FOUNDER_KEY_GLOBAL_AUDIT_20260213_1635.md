# SEAL: FOUNDER KEY GLOBAL AUDIT
**Date:** 2026-02-13
**Subject:** SSOT Validation, Logic Atlas, and Drift Prevention

## 1. Founder Key Atlas (Code Surface)

### 1.1 Founder-Gated Routes (Backend)
All routes under `/lab/*`, `/admin/*`, `/internal/*` are implicitly guarded by `PublicSurfaceShieldMiddleware`.
Specific routes use explicit dependencies or inline checks.

| Route | Guard Type | Auth Fail Response | Code Pointer |
| :--- | :--- | :--- | :--- |
| `/lab/*` (All) | **Shield Middleware** | `404 Not Found` (Fail-Hidden) | `api_server.py:66` |
| `/elite/*` (All) | **Dependency** (`require_elite_or_founder`) | `403 Forbidden` (Fail-Secure) | `api_server.py:1163` |
| `/lab/war_room/snapshot` | **Shield Middleware** | `404 Not Found` (Fail-Hidden) | `api_server.py:1043` |
| `/health_ext` | **Shield Middleware** (Explicit Check) | `404 Not Found` (Fail-Hidden) | `api_server.py:234` |
| `/lab/watchlist/log` | **Shield Middleware** | `404 Not Found` (Fail-Hidden) | `api_server.py:1315` |

### 1.2 Logic Validation (Exact Match)
- **Middleware (`PublicSurfaceShieldMiddleware`)**:
    - **Logic**: `if env_key and req_key_bytes:` then `if req_key == env_key:`
    - **Type**: Strict Equality (Byte-level comparison after UTF-8 decode).
    - **Fail-Hidden**: Returns hard 404 if auth fails.
- **Elite Gate (`require_elite_or_founder`)**:
    - **Logic**: Calls `is_founder(request)`.
    - **Implementation**: `backend/security/elite_gate.py`
    - **Comparison**: `if env_key and req_key and req_key == env_key:`
    - **Type**: Strict Equality.
    - **Fail-Secure**: Returns 403.

## 2. Runtime SSOT (GCP)

### 2.1 Cloud Run Service (`marketsniper-api`)
- **Revision**: `marketsniper-api-00037-4mt`
- **Env Vars**:
    - `FOUNDER_KEY`: `masked(len=14, prefix=mz_f)` (Verified Present)
    - `OUTPUTS_PATH`: `/app/outputs`
- **Traffic**: 100% to latest revision.
- **Status**: **SECURE & CONFIGURED**.

### 2.2 Cloud Run Job (`market-sniper-pipeline`)
- **Image**: `.../api:path_fix_...`
- **Env Vars**: `null` (No Founder Key).
- **Risk**: **HIGH DRIFT RISK**. If the pipeline job scripts leverage `/lab` endpoints for self-healing or maintenance, they *will fail* auth. Currently no evidence of such usage, but it is a latent break.

## 3. Live Behavior (Proofs)

### 3.1 Endpoint Verification (Responses)
- **`/lab/war_room/snapshot`**: `200 OK` (Auth Passed). Payload: `COMPUTE_ERROR` (Expected).
- **`/lab/os/health`**: `200 OK` (Auth Passed). Payload: `{"status":"ALIVE",...}`.
- **`/elite/os/snapshot`**: `200 OK` (Auth Passed). Payload: `OS UNAVAILABLE` (Expected).

### 3.2 Header Analysis
- **`X-Founder-Trace`**: `FOUNDER_BUILD=TRUE; KEY_SENT=True`.
- **Conclusion**: Middleware correctly identifies the key presence and the Environment Variable match allows `200 OK`.

## 4. Frontend Injection Audit

### 4.1 `ApiClient` Logic (`market_sniper_app`)
- **File**: `lib/services/api_client.dart`
- **Condition**:
    ```dart
    if (kIsWeb && kDebugMode && AppConfig.isFounderBuild) { ... }
    else if (kDebugMode && AppConfig.isFounderBuild && baseUrl.contains('localhost')) { ... }
    ```
- **Risk**:
    - **Mobile Release Builds**: Do **NOT** send `X-Founder-Key` (Security Feature).
    - **Mobile Debug Builds (Remote API)**: Do **NOT** send `X-Founder-Key` unless `baseUrl` is `localhost`.
    - **Web Debug Builds**: **ALWAYS** send `X-Founder-Key` if Founder Build.
- **Verdict**: **SAFE** for Public. **POTENTIAL FRICTION** for Founder Mobile Testing against Prod (requires `localhost` or Web).

## 5. Drift Prevention

### 5.1 Hardening Plan
1.  **Job Sync**: Add `FOUNDER_KEY` to `market-sniper-pipeline` to align with Service.
2.  **Local Check**: Use new `tools/verify_founder_key_surface.py` in pre-deploy hooks.

### 5.2 Verification Script
Created `tools/verify_founder_key_surface.py` which:
- Checks `backend/config.py` for correct env var definition.
- Checks Cloud Run Service config for `FOUNDER_KEY` presence.
- Returns non-zero exit code on failure.

## 6. Final Verdict
- **Atlas**: Mapped and Consistent.
- **SSOT**: Service Configured. Job Unconfigured (Drift Risk).
- **Proofs**: All critical endpoints verified `200 OK`.
- **Security**: Fail-Hidden (404) on Shield; Fail-Secure (403) on Elite. Zero Leaks detected.

**Status**: **AUDIT PASS**. (Recommendation: Sync Job Key).
