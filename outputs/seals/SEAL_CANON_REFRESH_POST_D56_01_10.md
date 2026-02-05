# SEAL: CANON REFRESH POST D56.01.10

**Date:** 2026-02-05
**Author:** Antigravity (Agent)
**Scope:** Canonical Documentation Refresh + System Checkpoint.

## 1. Truth Alignment (Post D56.01.10)
Aligned Canon with the "One-Shot Deployment" reality.

### A. Cloud Run Probes (Edge Bypass)
- **Problem**: Google Frontend (Edge) returns 404 for `/healthz` if unauthenticated.
- **Canon Fix**: Updated `DEPLOY_SMOKE_CHECKLIST.md` and `SYSTEM_ATLAS.md` to mandate `/lab/healthz` and `/lab/readyz`.
- **Reason**: Lab probes sit behind the `PublicSurfaceShieldMiddleware` allowlist, bypassing the Edge 404 issue while remaining unauthenticated for monitoring.

### B. Deployment Artifacts
- **Procfile**: Registered as the mandatory Entrypoint in `SYSTEM_ATLAS.md`.
- **Smoke Scripts**: `tools/smoke_cloud_run.ps1` and `.sh` are now tracked and referenced as Guardrails.

### C. Contract Registry
- **War Room**: Registered `backend/contracts/war_room_contract.py` in `OS_MODULES.md` as the SSOT for hydration and validation.

## 2. Updated Canon Files
- `docs/canon/ANTIGRAVITY_CONSTITUTION.md` (Verified)
- `docs/canon/DEPLOY_SMOKE_CHECKLIST.md` (Updated Probes)
- `docs/canon/OS_MODULES.md` (Added Contract + Cloud Run details)
- `docs/canon/SYSTEM_ATLAS.md` (Added Procfile + Probe Arch)
- `docs/canon/PENDING_LEDGER.md` (Synced)

## 3. Git Checkpoint
**Commit Message**: "Canon Refresh: post D56.01.10 truth alignment (probes, smoke, snapshot contract)"
**Includes**:
- All Canon updates.
- `Procfile`.
- `backend/api_server.py` (Lab Probes).
- `tools/smoke_cloud_run.*` (Guardrails).

## 4. Verdict
**STATUS: SEALED (CONSISTENT)**
The repository documentation now accurately reflects the production deployment architecture. No hidden state.
