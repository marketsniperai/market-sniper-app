# SEAL_D55_0E_FIREBASE_HOSTING_REWRITE_WEB_UNBLOCK

## 1. Executive Summary
- **Status**: **PARTIAL SUCCESS / MANUAL ACTION REQUIRED**.
- **Action**: Configured Firebase Hosting (`firebase.json`) to rewrite `/api/**` to `marketsniper-api` (Cloud Run).
- **Blocker**: `npm` and `firebase` CLI are missing from the current environment, preventing deployment and explicit Service Account creation.
- **Resolution**: User must run `firebase deploy --only hosting` manually.

## 2. Configuration Details
- **Rewrites**: `/api/**` -> `marketsniper-api` (us-central1).
- **Hosting URL**: `https://marketsniper-intel-osr-9953.web.app` (Assumed).
- **Backend URL**: `https://marketsniper-intel-osr-9953.web.app/api` (Configured in `AppConfig.dart` for Web).

## 3. Manual Steps Required
Run the following in `C:\MSR\MarketSniperRepo`:
1.  **Grant Permissions** (Try again after first deploy if SA was missing):
    ```powershell
    gcloud run services add-iam-policy-binding marketsniper-api --region us-central1 --member="serviceAccount:service-553550349208@gcp-sa-firebasehosting.iam.gserviceaccount.com" --role="roles/run.invoker"
    ```
2.  **Deploy**:
    ```powershell
    firebase deploy --only hosting
    ```

## 4. Verification Plan (Post-Deploy)
`curl -I https://marketsniper-intel-osr-9953.web.app/api/health_ext`
Should return **200 OK** (not 403, not 405).

## 5. Metadata
- **Date**: 2026-01-31
- **Task**: D55.0E
- **Status**: PARTIAL
