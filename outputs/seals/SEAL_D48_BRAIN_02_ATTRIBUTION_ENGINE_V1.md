# SEAL: Attribution Engine V1 (D48.BRAIN.02)

**Universal ID:** D48.BRAIN.02
**Title:** Attribution Engine V1 ("Show Work")
**Date:** 2026-01-28
**Author:** Antigravity (Agent)
**Status:** SEALED
**Type:** LOGIC

## 1. Manifest
- **Backend:** `ProjectionOrchestrator` updated to inject `use_attribution` payload.
- **Legacy Support:** Auto-injection of attribution for legacy cache hits.
- **Frontend:**
  - `AttributionSheet` (New Widget): Displays Inputs, Rules, and Restrictions.
  - `OnDemandPanel`: "Show Work" button integrated.
  - `AppColors`/`AppTypography`: Token compliance enforced.
- **Adapter:** `OnDemandAdapter` parses `AttributionModel`.

## 2. Verification
- **Backend:** `verify_d48_attribution_v1.py` confirms presence and structure of `attribution` object.
- **Frontend:** `flutter analyze` passing (functional baseline).
- **Smoke Test:** Configured to verify Tier-based filtering of restrictions.

## 3. Governance
- **Truth Surface:** Attribution is now a primary truth surface for Institutional Trust.
- **Tier Gating:** Explicitly explains *why* data is hidden (TierGate vs TimeGate).
- **Registry:** Extensions to `OS.Intel.Projection`.

## 4. Pending Closure Hook
Resolved Pending Items: None
New Pending Items: None
