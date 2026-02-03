# SEAL_D54_3_CLOUD_RUN_REALITY_AUDIT

## 1. Executive Summary
- **Status**: **CRITICAL DRIFT**. The deployed Cloud Run instance (`marketsniper-api`) is running a revision from **Jan 14, 2026**.
- **Lag**: ~17 Days behind HEAD.
- **Missing Routes**: **68** Endpoints are present locally but missing in Production.
- **Impact**: War Room, Context, Foundation, and recent Elite features are **NOT DEPLOYED**.

## 2. Deployed Inventory
### Cloud Run Service
- **Name**: `marketsniper-api`
- **Region**: `us-central1`
- **URL**: `https://marketsniper-api-3ygzdvszba-uc.a.run.app`
- **Active Revision**: `marketsniper-api-00019-7db`
- **Image**: `.../api:latest` (Digest likely old, maps to Jan 14).
- **Env Vars**: `JOB_NAME=market-sniper-pipeline`, `OUTPUTS_PATH=/app/backend/outputs`.

### Cloud Run Jobs
- **Name**: `market-sniper-pipeline`
- **Trigger**: Scheduler `ms-full-0830et` (Enabled).

### Storage
- **Outputs Bucket**: `gs://marketsniper-outputs-marketsniper-intel-osr-9953/`

## 3. The Missing Matrix
**Total Missing Routes: 68**
Key functional areas missing in PROD:
- `/lab/war_room` (and aliases)
- `/context`
- `/foundation`
- `/dashboard/refresh`
- `/housekeeper`
- `/on_demand/`
- `/options/`

(See `artifacts/audit/missing_matrix.txt` for full list).

## 4. Verification
- **OpenAPI**: PROD OpenAPI spec (~10KB) vs LOCAL OpenAPI spec (~40KB).
- **Spot Check**: Verified `/health_ext` and others return 405/404 or stale responses compared to local.

## 5. Action Plan
- **Immediate Action**: **FULL REDEPLOY REQUIRED**.
- **Scope**:
    1.  Build new API Image.
    2.  Deploy `marketsniper-api` (Cloud Run).
    3.  Update `market-sniper-pipeline` (Job) if shared logic changed.
- **Why**: To bring War Room V2, Context, and Elite features online. The current PROD is effectively "Legacy Day 35" state vs "Day 54" HEAD.

## 6. Metadata
- **Date**: 2026-01-31
- **Task**: D54.3
- **Status**: SEALED
