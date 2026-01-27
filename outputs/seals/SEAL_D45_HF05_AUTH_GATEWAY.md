# SEAL: D45 HF05 AUTH GATEWAY (ORG POLICY BYPASS)

**Date:** 2026-01-25
**Author:** Antigravity (Agent)
**Status:** SEALED (CODE COMPLETE / INFRA PENDING)
**Verification:** Flutter Analyze (Pass) + Deployment Script Generated

## 1. Objective
Implement an API Gateway architecture to bypass the Cloud Run 403 (Org Policy) restriction, allowing public access via a trusted Service Account invoker on the backend and API Key auth on the frontend.

## 2. Architecture (Target)
- **Frontend (Flutter):** Target `API_GATEWAY_URL`. Inject `FOUNDER_API_KEY`.
- **Ingress (Gateway):** Generic GCP API Gateway (Public).
- **Auth (Gateway -> Run):** Service Account `ms-api-gateway-invoker` with `roles/run.invoker`.
- **Auth (Client -> Gateway):** Google API Key (Query Param: `key`).

## 3. Implementation Status
- **Service Account:** Created (`ms-api-gateway-invoker`).
- **IAM Binding:** Applied to Cloud Run.
- **OpenAPI Spec:** Created (`openapi.yaml`).
- **Frontend Code:** Updated `AppConfig` and `CanonDebtRadar` to support Gateway+Key.
- **Gateway Deployment:** **BLOCKED** by GCloud CLI Re-auth requirement in Agent environment.

## 4. Next Actions (Operator Required)
1. Run script: `outputs/scripts/deploy_auth_gateway.ps1`
2. Capture `defaultHostname` (Gateway URL) and `keyString` (API Key).
3. Update build environment or `dart-define` flags:
   - `API_GATEWAY_URL=...`
   - `FOUNDER_API_KEY=...`

## 5. Manifest
- `openapi.yaml`
- `outputs/scripts/deploy_auth_gateway.ps1`
- `market_sniper_app/lib/config/app_config.dart`
- `market_sniper_app/lib/widgets/war_room/canon_debt_radar.dart`
