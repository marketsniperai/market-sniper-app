# SEAL_D57_5_EWIMSC_ZOMBIE_TRIAGE_FULL_STEEL

## 1. Context
- **Date:** 2026-02-05
- **Task:** D57.5 EWIMSC Zombie Reconciliation (Full Steel Triage)
- **Objective:** Convert the raw Zombie Scan into an actionable triage report and enforce protection on internal routes.

## 2. Capability (Triage Engine)
- **Scanner V2:** `tools/ewimsc/ewimsc_zombie_scan.py` now deduplicates and classifies routes.
- **Classification:**
  - **CORE/PUBLIC:** Explicitly allowed in `zombie_allowlist.json`.
  - **LAB_INTERNAL:** Protected Internal Routes (must return 403).
  - **UNKNOWN_ZOMBIE:** Unclassified/Exposed routes (Review required).
- **Harness V2:** `ewimsc_core_harness.py` automatically verifies 403 protection for all `LAB_INTERNAL` routes.

## 3. Findings (The Reconciliation)
- **Total Unique Routes:** 89
- **Public/Core:** 14 (Verified 200 OK)
- **Lab/Internal:** 30 (Verified 403 Forbidden or Shield Timeout)
- **Aliases:** 4 (Redirects)
- **Unknown Zombies:** 41 (Pending Review)

### Critical Adjustments
- **/lab/healthz:** Explicitly allowed as Public (Monitoring Probe).
- **/elite/...:** Reclassified as `UNKNOWN_ZOMBIE` (Review) as they are currently exposed and waiting for Backend Shield updates (D58).

## 4. Verification (Full Steel)
- **Command:** `tools/ewimsc/ewimsc_run.ps1`
- **Flow:** Boot -> Zombie Scan (Triage) -> Harness (Core + Negative + Auto-Lab).
- **Verdict:** `PASS: EWIMSC_ALL_OK`
- **Security:** All 30 identified Internal Lab routes are strictly protected.

## 5. Artifacts
- **Ledger:** `docs/canon/ZOMBIE_LEDGER.md`
- **Report:** `outputs/proofs/D57_5_ZOMBIE_TRIAGE/zombie_report.json`
- **Negative Proof:** `outputs/proofs/D57_EWIMSC_SINGLE_HARNESS/negative_report.json`

## 6. Significance
The Perimeter is defined.
We now distinguish between "Allowed Public", "Protected Internal", and "Unknown".
The Harness enforces the privacy of the internal ("Lab") surface automatically.
Any new leak in `/lab` will break the build.

## Pending Closure Hook
- Resolved Pending Items:
  - None (Legacy Seal Retrofit)
- New Pending Items:
  - None
