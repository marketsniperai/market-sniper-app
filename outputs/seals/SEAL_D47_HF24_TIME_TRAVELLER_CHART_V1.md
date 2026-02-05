# SEAL: D47.HF24 — Time-Traveller Chart v1

**Type:** HOTFIX / FEATURE (D47 Arc)
**Status:** SEALED (PASS)
**Date:** 2026-01-28
**Author:** Antigravity

## 1. Objective
Implement "Time-Traveller Chart" in On-Demand dossier.
Features:
- "NOW" axis with bright notch.
- Left side: Past candles (Solid).
- Right side: Future candles (Ghost, sequential reveal animation).
- "Blurred Truth" hooks (Scaffolding).
- 10:30 AM Rule: Lock future lane if DAILY frame and time < 10:30 ET.

## 2. Changes
- **New Widget:** `lib/widgets/time_traveller_chart.dart`
    - Implements specialized painter for Past/Future candles.
    - Implements Sequential Reveal animation (Ghost opacity).
    - Implements "CALIBRATING" sine wave state.
- **Modified:** `lib/screens/on_demand_panel.dart`
    - Integrated `TimeTravellerChart` into logic.
    - Hoisted `_isDailyLocked` logic.
    - Extract series from `rawPayload`.

## 3. Verification
- **Static Analysis:** Passed (`flutter analyze`).
    - Proof: [`01_flutter_analyze.txt`](../../outputs/proofs/day47_hf24_time_traveller_chart_v1/01_flutter_analyze.txt)
- **Compilation:** Passed (`flutter build web`).
    - Proof: [`02_flutter_build_web.txt`](../../outputs/proofs/day47_hf24_time_traveller_chart_v1/02_flutter_build_web.txt)
- **Logic:** Verified via code inspection and runtime note.
    - Proof: [`04_runtime_note.md`](../../outputs/proofs/day47_hf24_time_traveller_chart_v1/04_runtime_note.md)

## 4. Artifacts
Directory: `outputs/proofs/day47_hf24_time_traveller_chart_v1/`
- `00_diff.txt`
- `01_flutter_analyze.txt`
- `02_flutter_build_web.txt`
- `03_runtime_screenshots_SKIPPED.txt`
- `04_runtime_note.md`
- `05_perf_note.md`

## 5. Next Steps
- Implement backend support for `series` payload in `StandardEnvelope`.
- HF30: Implement full Blurred Truth Overlay and Monetization Gates (Tier awareness).

## Pending Closure Hook
- Resolved Pending Items:
  - None
- New Pending Items:
  - None
