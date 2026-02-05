# SEAL: D47.HF25 — Reliability Meter

**Type:** HOTFIX / FEATURE (D47 Arc)
**Status:** SEALED (PASS)
**Date:** 2026-01-28
**Author:** Antigravity

## 1. Objective
Implement "Reliability Meter" in On-Demand dossier to explain confidence without trade signals.
Features:
- **State Display:** HIGH / MED / LOW / CALIBRATING.
- **Support Chips:** Samples (N=#), Drift (N/A), Inputs (Live/Total).
- **Logic:** Derived from `projection.state`, `sample_size`, and Daily Lock.
- **Signals-Free:** Purely descriptive of engine confidence.

## 2. Changes
- **New Widget:** `lib/widgets/reliability_meter.dart`
    - Logic-free UI component.
    - Handles color mapping (AppColors).
- **Modified:** `lib/screens/on_demand_panel.dart`
    - Integrated `ReliabilityMeter` below `TimeTravellerChart`.
    - Implemented logic mapper `_buildReliabilityMeter`.
    - Connects to `rawPayload` for evidence/inputs.

## 3. Verification
- **Static Analysis:** Passed (`flutter analyze`).
    - Proof: [`01_flutter_analyze.txt`](../../outputs/proofs/day47_hf25_reliability_meter/01_flutter_analyze.txt)
- **Compilation:** Passed (`flutter build web`).
    - Proof: [`02_flutter_build_web.txt`](../../outputs/proofs/day47_hf25_reliability_meter/02_flutter_build_web.txt)
- **Logic:** Verified via code inspection and runtime note.
    - Proof: [`04_runtime_note.md`](../../outputs/proofs/day47_hf25_reliability_meter/04_runtime_note.md)

## 4. Artifacts
Directory: `outputs/proofs/day47_hf25_reliability_meter/`
- `00_diff.txt`
- `01_flutter_analyze.txt`
- `02_flutter_build_web.txt`
- `03_runtime_screenshots_SKIPPED.txt`
- `04_runtime_note.md`
- `05_sample_payload.json`

## 5. Next Steps
- HF26: Intel Cards implementation.
- HF30: Full Gating mechanics.

## Pending Closure Hook
- Resolved Pending Items:
  - None
- New Pending Items:
  - None
