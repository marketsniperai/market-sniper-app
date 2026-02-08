# SEAL_D57_EWIMSC_SINGLE_HARNESS

## 1. Context
- **Date:** 2026-02-05
- **Task:** D57.EWIMSC.SINGLE_HARNESS
- **Objective:** Create a single, deterministic command to verify the "EWIMSC Truth" (Core + Contracts).

## 2. The Harness
- **Command:** `powershell -ExecutionPolicy Bypass -File tools/ewimsc/ewimsc_run.ps1`
- **Mechanism:**
    1. Finds free port (8787+).
    2. Boots Backend (`ENV=local`).
    3. Runs `ewimsc_core_harness.py`.
    4. Validates 8 CORE Endpoints + Envelope Contracts.
    5. Exits 0 (PASS) or 1 (FAIL).

## 3. Verification Results
- **Verdict:** **PASS: EWIMSC_CORE_OK**
- **Endpoints Verified:**
    - `/lab/healthz` (Critical)
    - `/dashboard` (Envelope + Status)
    - `/context` (Envelope + Status)
    - `/agms/foundation` (Data Truth)
    - `/pulse` (Realtime)
    - `/briefing` (Reporting)
    - `/aftermarket` (Reporting)
    - `/news_digest` (Intel)

## 4. Evidence
- **Console Output:** `pass`
- **Proof:** `outputs/proofs/D57_EWIMSC_SINGLE_HARNESS/VERDICT.txt`
- **Report:** `outputs/proofs/D57_EWIMSC_SINGLE_HARNESS/core_report.json`

## 5. Significance
This seal establishes the **"One Command" Doctrine**. No feature is considered "EWIMSC SAFE" unless it passes this harness. Future audits will rely on this binary verdict.

**TRUTH:** THE HARNESS IS THE LAW.

## Pending Closure Hook
- Resolved Pending Items:
  - None (Legacy Seal Retrofit)
- New Pending Items:
  - None
