# SEAL_D55_1B_ZERO_HUMAN_FIREBASE_SA_AND_HOSTING_DEPLOY

## 1. Executive Summary
- **Status**: **FAILED (Platform Constraints)**.
- **Goal**: Provision Firebase Hosting Service Agent and Deploy Rewrites without human interaction.
- **Blockers**:
    1. `gcloud beta services identity create`: Failed with `SU_INTERNAL_GENERATE_SERVICE_IDENTITY` (GCP Error).
    2. Cloud Build `firebase deploy`: Failed (Exit Code 1), likely due to authentication requirements that cannot be met non-interactively without a pre-existing token.
- **Result**: The necessary Service Agent `service-553550349208@...` does **NOT** exist. Hosting Rewrites are **NOT** active.

## 2. MANUAL RESOLUTION (MANDATORY)
The user must perform the initial deployment manually to bootstrap the Service Identity.

**Step 1: Deploy Hosting (Bootstrap)**
Run from root (`C:\MSR\MarketSniperRepo`):
```powershell
firebase deploy --only hosting
```
*Verification: Access `https://marketsniper-intel-osr-9953.web.app/api/health_ext`. Expect 403 Forbidden (Service Agent exists but has no permission).*

**Step 2: Grant Permissions**
Run:
```powershell
gcloud run services add-iam-policy-binding marketsniper-api --region us-central1 --member="serviceAccount:service-553550349208@gcp-sa-firebasehosting.iam.gserviceaccount.com" --role="roles/run.invoker"
```
*Verification: Access `https://marketsniper-intel-osr-9953.web.app/api/health_ext`. Expect 200 OK.*

## 3. Metadata
- **Date**: 2026-01-31
- **Task**: D55.1B
- **Status**: FAILED_MANUAL_REQUIRED
