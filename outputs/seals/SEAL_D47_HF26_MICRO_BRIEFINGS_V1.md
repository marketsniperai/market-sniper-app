# SEAL: D47.HF26 — Intel Cards v1 (Micro-Briefings)

**Type:** HOTFIX / FEATURE (D47 Arc)
**Status:** SEALED (PASS)
**Date:** 2026-01-28
**Author:** Antigravity

## 1. Objective
Implement "Intel Cards" in On-Demand dossier to provide compact, high-value micro-briefings from Chronos, News, and Macro engines at a glance.
Cards:
1. **Probability Engine** (Evidence: Win Rate / Avg Move)
2. **Catalyst Radar** (News: Headlines / Focus)
3. **Regime & Structure** (Macro: Context)

## 2. Changes
- **Backend:** `backend/os_intel/projection_orchestrator.py`
    - Modified to expose `inputs.evidence.metrics` (win_rate, avg_return).
    - Modified to expose `inputs.news.headlines` (Top 3).
- **New Widget:** `lib/widgets/intel_card.dart`
    - Reusable Premium UI card with vertical accent bar, icon, title, body, tooltip.
- **Modified:** `lib/screens/on_demand_panel.dart`
    - Integrated 3 Intel Cards below Reliability Meter.
    - Implemented `_buildIntelInterface` with fallback logic (CALIBRATING/OFFLINE).

## 3. Verification
- **Static Analysis:** Passed (`flutter analyze`).
    - Proof: [`01_flutter_analyze.txt`](../../outputs/proofs/day47_hf26_micro_briefings_v1/01_flutter_analyze.txt)
- **Compilation:** Passed (`flutter build web`).
    - Proof: [`02_flutter_build_web.txt`](../../outputs/proofs/day47_hf26_micro_briefings_v1/02_flutter_build_web.txt)
- **Logic:** Verified via code inspection and runtime note.
    - Proof: [`04_runtime_note.md`](../../outputs/proofs/day47_hf26_micro_briefings_v1/04_runtime_note.md)

## 4. Artifacts
Directory: `outputs/proofs/day47_hf26_micro_briefings_v1/`
- `00_diff.txt`
- `01_flutter_analyze.txt`
- `02_flutter_build_web.txt`
- `03_runtime_screenshots_SKIPPED.txt`
- `04_runtime_note.md`
- `05_sample_payload.json`

## 5. Next Steps
- HF30: Full Gating mechanics.
