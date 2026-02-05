# SEAL: D47.HF23 — On-Demand Timeframe Control (DAILY/WEEKLY)

**Type:** HOTFIX / FEATURE (D47 Arc)
**Status:** SEALED (PASS)
**Date:** 2026-01-28
**Author:** Antigravity

## 1. Objective
Implement Timeframe Control for On-Demand Intelligence, allowing users to switch between "DAILY" and "WEEKLY" views. Introduce the "10:30 AM Rule" for the DAILY timeframe, locking the AI output during the calibration window (09:30–10:30 ET).

## 2. Changes
- **Dependency:** `market_sniper_app` (Frontend Only)
- **Files Modified:**
  - `lib/services/api_client.dart`: Added `timeframe` parameter to `fetchOnDemandContext`.
  - `lib/screens/on_demand_panel.dart`:
    - Added `_timeframe` state (DAILY/WEEKLY).
    - Implemented UI Selector (DAILY=Neon Cyan, WEEKLY=Gold/Stale).
    - Implemented `_buildLockBannerIfNeeded` (10:30 AM logic for DAILY).
    - Wired `_analyze()` to pass `timeframe` to API.

## 3. Verification
- **Static Analysis:**
  - `flutter analyze` passed (0 issues).
  - Proof: [`01_flutter_analyze.txt`](../../outputs/proofs/day47_hf23_on_demand_timeframe_control/01_flutter_analyze.txt)
- **Compilation:**
  - `flutter build web` passed (Exit Code 0).
  - Proof: `build_web_log.txt` (Logged in shell)
- **Logic:**
  - Verified logic via code inspection and runtime note.
  - Proof: [`04_runtime_note.md`](../../outputs/proofs/day47_hf23_on_demand_timeframe_control/04_runtime_note.md)

## 4. Artifacts
- **Proof Directory:** `outputs/proofs/day47_hf23_on_demand_timeframe_control/`
- **Mock Response:** [`05_sample_responses.json`](../../outputs/proofs/day47_hf23_on_demand_timeframe_control/05_sample_responses.json)

## 5. Next Steps
- Verify visual polish in upcoming D48/Polish sessions.
- Ensure backend (Projection Orchestrator) fully supports `WEEKLY` context generation (Stub enabled).

## Pending Closure Hook
- Resolved Pending Items:
  - None
- New Pending Items:
  - None
