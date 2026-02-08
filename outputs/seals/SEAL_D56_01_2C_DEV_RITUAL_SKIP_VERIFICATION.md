# SEAL: D56.01.2C — DEV_RITUAL “SKIP IS LYING” (SESSION KEY DRIFT FIX)

> **Date:** 2026-02-05
> **Author:** Antigravity (Agent)
> **Task:** D56.01.2C
> **Status:** SEALED
> **Type:** IMPLEMENTATION + HARDENING

## 1. Context (The Assumption Gap)
Previously, `dev_ritual.ps1` would verify if Port 8000 was active. If active, it would `[SKIP]` the backend start, assuming the running instance was valid. Use cases where the backend was started with a different key (Drift) were silently ignored, causing "Key Sent but Forbidden" (403) errors in the Frontend.

## 2. Implementation: Verified Skip
Updated `tools/dev_ritual.ps1` to replace the blind skip with a **Cryptographic Probe**:
1.  **Probe**: `curl -H "X-Founder-Key: $founderKey" ...` against the active port.
2.  **Verify**: If `200 OK`, proceed (Verified Skip).
3.  **Heal**: If NOT 200 (403, 404, 500, Connection Refused):
    -   Log `[DRIFT] Session Mismatch detected`.
    -   **Kill** the drifting PID on Port 8000.
    -   **Restart** the backend with the correct `$env:FOUNDER_KEY`.

## 3. Verification Scenarios

### A. Drift Detection (Simulated)
-   **Setup**: Backend started with `FOUNDER_KEY=DRIFT_TEST`.
-   **Action**: Ran `dev_ritual.ps1` (Default Key: `mz_founder_888`).
-   **Result**:
    -   Log: `[DRIFT] Verified Probe Failed (Code: {"detail":"Forbidden: Shield Active"}).`
    -   Action: `[KILL] Terminating Instance...` -> `[REBOOT] Starting Fresh Backend...`
    -   Status: **PASSED.**

### B. Verified Skip (Aligned)
-   **Setup**: Backend running with `mz_founder_888` (Healed from Scenario A).
-   **Action**: Ran `dev_ritual.ps1` (Default Key: `mz_founder_888`).
-   **Result**:
    -   Log: `[VERIFIED] Backend Session Key matches. Skipping start.`
    -   Status: **PASSED.**

### C. Final Proofs (Curl)
-   **Hostile Path**: `curl ...` (No Header) -> **403 Forbidden**.
-   **Founder Path**: `curl -H "X-Founder-Key: mz_founder_888" ...` -> **200 OK**.

## 4. Manifest
-   `tools/dev_ritual.ps1` (Logic Update)

## Pending Closure Hook
- Resolved Pending Items:
  - None (Legacy Seal Retrofit)
- New Pending Items:
  - None
