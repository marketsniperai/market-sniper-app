# SEAL: D56.01.9 - CLOUD RUN SMOKE TEST + DEPLOY GUARDRAILS

**Date:** 2026-02-05
**Author:** Antigravity (Agent)
**Scope:** Automated Smoke Tests, Contract Extraction, Deployment Verification Guardrails.

## 1. Problem Statement
Deployments to Cloud Run were "hope-based" without a strict, automated way to verify:
1.  Port binding success.
2.  Health/Readiness probes.
3.  War Room Snapshot validity (Schema + Auth).
4.  Secret safety (No leaked keys in logs).

## 2. Solution Implemented
### A. Contract Extraction (SSOT)
- **Extracted**: `REQUIRED_KEYS` moved to `backend/contracts/war_room_contract.py`.
- **Refactored**: `war_room.py` imports this contract. Ensures Backend and Smoke Tests agree on "What is a valid snapshot".

### B. Automated Smoke Tests (Guardrails)
- **PowerShell**: `tools/smoke_cloud_run.ps1` for Windows/CI.
- **Bash**: `tools/smoke_cloud_run.sh` for Linux/Cloud Shell (Action-Ready).
- **Checks**:
    - `/healthz` -> 200 ALIVE
    - `/readyz` -> 200 READY
    - Snapshot (No Key) -> 403 Forbidden
    - Snapshot (Safe Key) -> 200 OK + `contract_version=USP-1` + `missing_modules=[]` + Key Count >= 21.

### C. Deployment Procedure
- **Checklist**: `docs/canon/DEPLOY_SMOKE_CHECKLIST.md`.
- **Mandate**: No deployment is done until smoke test shows GREEN.

## 3. Verification Proofs (Local Simulation)
**Scenario**: `PORT=8081`, `SYSTEM_MODE=PROD`.
**Tool**: `tools/smoke_cloud_run.ps1`

| Check | Expected | Result |
|:---|:---|:---|
| **Health Probe** | 200 ALIVE | [x] PASS |
| **Ready Probe** | 200 READY | [x] PASS |
| **Auth Shield** | 403 Forbidden | [x] PASS |
| **Snapshot Schema** | USP-1 | [x] PASS |
| **Zero Missing** | `missing_modules: []` | [x] PASS |
| **Module Keys** | Count >= 21 | [x] PASS |

**Exit Code**: 0 (Success)

## 4. Manifest
- [NEW] `backend/contracts/war_room_contract.py`
- [NEW] `tools/smoke_cloud_run.ps1`
- [NEW] `tools/smoke_cloud_run.sh`
- [NEW] `docs/canon/DEPLOY_SMOKE_CHECKLIST.md`

## 5. Verdict
**STATUS: SEALED (GUARDED)**
The system now has a standardized, automated definition of "Healthy Deployment". CI/CD pipelines can now "Gate on Green" with zero ambiguity.

## Pending Closure Hook
- Resolved Pending Items:
  - None (Legacy Seal Retrofit)
- New Pending Items:
  - None
