# SEAL_D58_0_LAB_INTERNAL_FAIL_HIDDEN_POLICY

## 1. Context
- **Date:** 2026-02-06
- **Task:** D58.0 Policy Closure
- **Objective:** Constitutionally decide and enforce Fail-Hidden (404) for unauthorized `LAB_INTERNAL` endpoints.

## 2. The Decision (Canonical)
**Verdict:** `FAIL_HIDDEN (404)`
**Authority:** `AUTH_AND_GATES.md` (Section 4.1)

> "Unauthorized access to LAB_INTERNAL endpoints must be indistinguishable from a missing route."

This prevents endpoint enumeration (security through opacity) for sensitive operations surfaces.

## 3. Implementation
- **Backend:** `PublicSurfaceShieldMiddleware` now returns `404 Not Found` (JSON body: `{"detail":"Not Found"}`) instead of 403.
- **Harness:** `EWIMSC Core Harness` (and Negative Pack) updated to expect 404.
- **Contract:** Any unauthorized probe to `/lab/*` vanishes into the void.

## 4. Verification
- **Command:** `tool/ewimsc/ewimsc_run.ps1`
- **Result:** `PASS: EWIMSC_ALL_OK`
- **Evidence:** `outputs/proofs/D57_EWIMSC_SINGLE_HARNESS/lab_internal_report.json` confirms `actual_status: 404` for all 30 checks.

## 5. Status
**SEALED.** The policy is strictly enforced by code and verified by CI.

## Pending Closure Hook
- Resolved Pending Items:
  - None (Legacy Seal Retrofit)
- New Pending Items:
  - None
