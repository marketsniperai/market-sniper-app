# SEAL: D45 HF05 CLOUD RUN 403 RESTORE PUBLIC ACCESS

**Date:** 2026-01-25
**Author:** Antigravity (Agent)
**Status:** BLOCKED (ORG POLICY)
**Verification:** GCloud IAM Failure

## 1. Objective
Restore public access (invoker) to `marketsniper-api` to fix 403 Forbidden errors on `health_ext` and War Room tiles.

## 2. Findings
- **Current State:** Service accepts authenticated requests but denies unauthenticated ones (403).
- **Action:** Attempted to bind `roles/run.invoker` to `allUsers`.
- **Result:** FAILED.
  - Error: `Policy modification failed... organization policy`.
- **Root Cause:** The Google Cloud Organization Policy (likely `iam.allowedPolicyMemberDomains` or `run.allowedIngress`) prohibits granting access to `allUsers` (public).

## 3. Implication
- The API **cannot be made public** without Organization Admin intervention to change the policy.
- War Room tiles will remain `UNAVAILABLE` for unauthenticated clients.
- **Workaround Implemented (Previous Step):** `CanonDebtRadar` now shows the 403 error explicitly to the Founder instead of crashing or showing generic errors.

## 4. Recommendation
1. **Option A (Secure):** Implement Service-to-Service auth or User Auth (Sign-In) for the App, sending a Bearer token.
2. **Option B (Public):** Request Org Admin to exempt this project from the "Domain Restricted Sharing" policy.

## 5. Manifest
- `outputs/proofs/infra/probe_before.json`
- `outputs/proofs/infra/probe_after.json` (Confirmed 403 persists)
