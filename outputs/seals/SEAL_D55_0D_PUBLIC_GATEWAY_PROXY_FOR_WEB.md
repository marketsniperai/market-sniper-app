# SEAL_D55_0D_PUBLIC_GATEWAY_PROXY_FOR_WEB

## 1. Executive Summary
- **Status**: **BLOCKED / PARTIAL FAILURE**.
- **Action**: Deployed `marketsniper-gateway` to Cloud Run.
- **Issue**: Organization Policy `iam.allowedPolicyMemberDomains` (or similar) prevents adding `allUsers` (Public Access) to the Cloud Run service.
- **Impact**: The Gateway cannot answer `OPTIONS` preflight requests from the browser because Cloud Run rejects unauthenticated requests *before* the container code runs.
- **Result**: `curl ... OPTIONS` returns **403 Forbidden**.

## 2. Deployment Details
- **Service**: `marketsniper-gateway`
- **Region**: `us-central1`
- **URL**: `https://marketsniper-gateway-3ygzdvszba-uc.a.run.app`
- **Image**: `gateway:D55.0D`
- **Service Account**: `ms-api-gateway-invoker@...`

## 3. Evidence of Blockage
`gcloud run services add-iam-policy-binding ... --member=allUsers ...`
> **ERROR**: Policy modification failed. ... an organization policy.

## 4. Recommendation
To bypass CORS/Auth on Cloud Run without public access, use **Firebase Hosting Rewrites**:
1. Connect `marketsniper-api` to Firebase Hosting.
2. Add rewrite in `firebase.json`:
   ```json
   "rewrites": [ { "source": "/api/**", "run": { "serviceId": "marketsniper-api", "region": "us-central1" } } ]
   ```
3. Flutter Web calls `https://<FIREBASE_DOMAIN>/api/...`.
   Firebase Hosting handles the OPTIONS preflight automatically or allows it through same-origin.

## 5. Metadata
- **Date**: 2026-01-31
- **Task**: D55.0D
- **Status**: BLOCKED
