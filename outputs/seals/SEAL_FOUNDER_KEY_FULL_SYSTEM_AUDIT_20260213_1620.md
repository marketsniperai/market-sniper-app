# SEAL: FOUNDER KEY FORENSICS — FULL SYSTEM AUDIT
**Date:** 2026-02-13
**Subject:** SSOT Validation & Root Cause of Auth Failure (404)

## 🧱 SEAL 1 — CODE SURFACE TRUTH

### 1.1 Env Variable Name (Canonical)
- **File**: `backend/config.py` (Line 24)
- **Code**: 
  ```python
  FOUNDER_KEY = os.getenv("FOUNDER_KEY", "")
  ```
- **Fact**: Variable name is strictly `FOUNDER_KEY`.
- **Default**: Empty string `""`. 
- **Impact**: If env var is missing, `FOUNDER_KEY` becomes `""`.

### 1.2 Middleware Logic (Fail-Hidden Mechanism)
- **File**: `backend/api_server.py` (lines 66-126)
- **Class**: `PublicSurfaceShieldMiddleware`
- **Logic**:
  ```python
  90: env_key = BackendConfig.FOUNDER_KEY
  98: if env_key and req_key_bytes:             # <--- CRITICAL GATE
  99:      if req_key_bytes.decode("utf-8") == env_key:
  100:         authorized = True
  ```
- **Mechanism**: 
  - The check `if env_key` **FAILS** if `env_key` is empty string.
  - Therefore, if Cloud Run lacks the env var, `authorized` is **ALWAYS False**, even if `req_key_bytes` (KEY_SENT) is present.
- **Fail-Hidden Response**:
  ```python
  113: # D58.0: Fail-Hidden (404) for LAB_INTERNAL
  115: body = b'{"detail":"Not Found"}'
  121: await send({"type":"http.response.start","status":404,...})
  ```

### 1.3 Snapshot Route Guards
- **Route**: `@app.get("/lab/war_room/snapshot")` (Line 1043)
- **Guard**: `PublicSurfaceShieldMiddleware` applies globally to all paths starting with `/lab` (Line 75).
- **Exclusion**: None for this path.
- **Verdict**: Protected by Fail-Hidden logic.

---

## 🧱 SEAL 2 — RUNTIME CONFIG TRUTH (GCP)

### 2.1 Active Revision
- **Command**: `gcloud run services describe marketsniper-api ...`
- **Output**: `marketsniper-api-00037-4mt`
- **Verdict**: Verified.

### 2.2 Env Vars in Revision
- **Command**: `gcloud run services describe ...`
- **Output**:
  ```yaml
  - name: FOUNDER_KEY
    value: mz_founder_888
  ```
- **Verdict**: **PRESENT** (in current revision 37). *Note: Was MISSING in prior revisions, causing the issue.*

### 2.3 Traffic
- **Output**: `100%` to `marketsniper-api-00037-4mt`.
- **Verdict**: No shadow revisions.

### 2.4 Cloud Run Job
- **Command**: `gcloud run jobs describe market-sniper-pipeline`
- **Output**: `null` (Env vars).
- **Verdict**: Job does **NOT** have `FOUNDER_KEY` injected. (Potential drift if pipeline needs it, but outside scope of Snapshot route).

---

## 🧱 SEAL 3 — LIVE AUTH BEHAVIOR FORENSICS

### 3.1 & 3.2 Curl Trace
- **Command**: `curl -i -H "X-Founder-Key: mz_founder_888" ...`
- **Result (Post-Fix)**: `200 OK`.
- **Trace Analysis (Pre-Fix/404)**:
  - Header: `x-founder-trace: FOUNDER_BUILD=TRUE; KEY_SENT=True`
  - Body: `404 Not Found`
  - **Explanation**: `KEY_SENT=True` comes from `founder_middleware` (Line 140: `is_founder = founder_key is not None`). This middleware checks **presence only**.
  - However, `PublicSurfaceShieldMiddleware` (the Gate) checked **equality AND server-side configuration** (`if env_key and ...`).
  - **Paradox Resolved**: It is possible to have `KEY_SENT=True` (Client sent it) but `authorized=False` (Server didn't have a key to match against).

### 3.3 Strict Equality Check
- **Code**: `if req_key_bytes.decode("utf-8") == env_key:`
- **Verdict**: **STRICT**. No partial match, no trimming implies exact string match required.

---

## 🧱 SEAL 4 — DRIFT HYPOTHESES

| Hypothesis | Status | Proof |
| :--- | :--- | :--- |
| **Trailing Whitespace** | FALSE | Current config works with exact match. |
| **Middleware Presence check only** | FALSE | Code uses strict `==`. |
| **Server Key Missing** | **TRUE** | (Historical) Audit of previous state showed empty env vars. |
| **Logic Flaw (Empty Key)** | **TRUE** | `if env_key` prevents access if config is missing. |
| **Header Stripping** | FALSE | `KEY_SENT=True` proves header reached app. |

---

## 🧱 SEAL 5 — FINAL ROOT CAUSE

The persistent 404 despite `KEY_SENT=True` was caused by the **absence of the `FOUNDER_KEY` environment variable** in the Cloud Run service configuration.

The `PublicSurfaceShieldMiddleware` correctly implements a "Fail-Closed" logic:
`if env_key and req_key_bytes:`
Because `env_key` resolved to an empty string (default), the guard condition failed immediately, triggering the "Fail-Hidden" (404) response. The `x-founder-trace` header is injected by a separate middleware (`founder_middleware`) which only checks for the *presence* of the header in the request, leading to the confusing `KEY_SENT=True` diagnostic on a 404 response.

---

## 🧱 SEAL 6 — HARDENING RECOMMENDATION

### Minimal Config Fix (Executed)
- **Action**: Set `FOUNDER_KEY` in Cloud Run Environment Variables.
- **Value**: `mz_founder_888` (Matches Client SSOT).

### Code Recommendation (No Refactor, just Note)
- The current logic is **Secure by Design** (Fail-Closed). Do not change it to allow access if server key is missing.
- **Drift Prevention**: Ensure `FOUNDER_KEY` is added to the `market-sniper-pipeline` job if it requires authenticated access to the API (currently distinct).

**Status**: SYSTEM HEALTHY. SNAPSHOT UNBLOCKED.
