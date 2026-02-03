# SEAL_D54_2B_PY_DEV_PROXY_FOR_WEB

## 1. Description
This seal certifies the creation of a Local Development Proxy (Python/FastAPI) to enable Flutter Web debugging against the private Cloud Run API. This solves the "403 Forbidden" / CORS issues inherent in accessing authenticated Cloud Run services directly from a browser.

## 2. Root Cause Analysis
- **Constraint**: Cloud Run services with `ingress: internal-and-cloud-load-balancing` or requiring IAM Auth cannot be accessed directly by a browser (Flutter Web) due to:
    1.  **CORS**: Browsers block cross-origin requests unless explicitly allowed (Cloud Run strips headers on 403).
    2.  **Auth**: Browser cannot securely sign requests with `gcloud` credentials automatically.
- **Solution**: A local "Backend-for-Frontend" (BFF) proxy executing in the user's OS shell.

## 3. Resolution
- **Tool**: `market_sniper_app/tools/dev_proxy/proxy.py` (FastAPI + httpx).
- **Logic**:
    - Listens on `http://localhost:8787` (CORS safe).
    - Intercepts requests.
    - Executes `gcloud auth print-identity-token` to get a fresh bearer token.
    - Injects `Authorization: Bearer <token>` header.
    - Forwards request to `MARKETSNIPER_API_URL` (Cloud Run).
    - Returns response to Flutter Web.
- **Config**: Updated `AppConfig.dart` to use `http://localhost:8787` ONLY when `kIsWeb && kDebugMode`.

## 4. Verification
- **Proxy Output**:
    ```
    [PROXY] GET /health_ext -> https://.../health_ext
    [PROXY] <- 200
    ```
- **Curl**: `curl http://localhost:8787/health_ext` returns 200 OK (verified).
- **Integration**: Flutter Web (Debug) now successfully fetches War Room data.

## 5. Metadata
- **Date**: 2026-01-31
- **Task**: D54.2B
- **Status**: SEALED
- **Next**: D55 (Release)
