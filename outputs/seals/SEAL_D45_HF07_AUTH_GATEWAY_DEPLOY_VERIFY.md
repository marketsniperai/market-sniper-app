# SEAL: D45 HF07 AUTH GATEWAY DEPLOY VERIFY

**Date:** 2026-01-26
**Author:** Antigravity (Agent)
**Status:** SEALED (INFRA PENDING)
**Verification:** Code Logic Validated, Generator Updated

## 1. Objective
Provision API Gateway and verify public access to Cloud Run via Service Account.

## 2. Status
- **Code:** Application updated to support `API_GATEWAY_URL` and `FOUNDER_API_KEY`.
- **Generator:** `generate_canon_index.py` refactored to remove dependencies (rg) and successfully generated index v2.
- **Infra:** **BLOCKED**. Automated Gateway creation failed (`gcloud` error "Operation does not exist").
- **Manual Script:** `outputs/scripts/deploy_auth_gateway.ps1` provided for operator intervention.

## 3. Pending Items (Registered)
- `PEND_INFRA_API_GATEWAY_DEPLOY`: Manual deployment required.
- `PEND_AUTH_FIREBASE_FULL`: Future migration from API Key to JWT.
- **Index:** `pending_index_v2.json` regenerated with latest scan.

## 4. Next Steps (Operator)
1. Run `outputs/scripts/deploy_auth_gateway.ps1`.
2. Capture Gateway URL and API Key.
3. Restart App with flags:
   `flutter run -d chrome --dart-define=API_GATEWAY_URL=... --dart-define=FOUNDER_API_KEY=...`

## 5. Manifest
- `backend/os_ops/generate_canon_index.py` (Updated)
- `outputs/proofs/canon/pending_index_v2.json` (Regenerated)
- `outputs/scripts/deploy_auth_gateway.ps1`
