# SEAL_D55_1_WEB_ACCESS_UNBLOCK_ZERO_HUMAN_ATTEMPT

## 1. Executive Summary
- **Status**: **FAILED (Env Constraints)**.
- **Goal**: Unblock Web Access without manual interaction.
- **Blocker**: The Firebase Hosting Service Agent (`service-553550349208@...`) does not exist. It is only created upon the *first successful hosting deployment*. 
- **Constraint**: I cannot perform the first deployment because:
    1. Local `firebase` CLI is missing/broken.
    2. Cloud Build `firebase deploy` failed (likely due to Auth/Interactive requirements or pathing).
- **Result**: The Web App remains configured for Hosting, but Hosting is not active.

## 2. Prepared State
I have configured the repository so a single user command will solve the entire issue.
- **Configured**: `firebase.json` (Rewrites to Cloud Run).
- **Configured**: `.firebaserc` (Project ID).
- **Configured**: `cloudbuild_firebase.yaml` (CI/CD Pipeline).
- **Configured**: `AppConfig.dart` (Points to Hosting URL).

## 3. UNBLOCKING STEPS (USER ACTION)
You must perform the **First Deploy** manually from a machine with `firebase` CLI logged in.

1. **Deploy Hosting**:
   ```bash
   firebase deploy --only hosting
   ```
   *This triggers the creation of the Service Agent.*

2. **Grant Permission** (Wait 30s after deploy):
   ```bash
   gcloud run services add-iam-policy-binding marketsniper-api \
     --region us-central1 \
     --member="serviceAccount:service-553550349208@gcp-sa-firebasehosting.iam.gserviceaccount.com" \
     --role="roles/run.invoker"
   ```

3. **Verify**:
   Access `https://marketsniper-intel-osr-9953.web.app/api/health_ext` -> **200 OK**.

## 4. Metadata
- **Date**: 2026-01-31
- **Task**: D55.1
- **Status**: MANUAL_REQUIRED
