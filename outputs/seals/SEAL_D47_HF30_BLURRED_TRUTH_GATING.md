# SEAL: D47.HF30 — Blurred Truth Gating (UI-Only)

**Type:** HOTFIX / FEATURE (D47 Arc)
**Status:** SEALED (PASS)
**Date:** 2026-01-28
**Author:** Antigravity

## 1. Objective
Implement "Blurred Truth" gating for forward-looking and detailed tactical intelligence, ensuring premium "Institutional Envy" without blocking past factual data.

## 2. Changes
- **UI:** Created `BlurredTruthOverlay` (Glassmorphic Blur + Lock Icon).
- **Widgets:**
    - `TimeTravellerChart`: Added `blurFuture` support. Renders overlay on the right side of the NOW line.
    - `TacticalPlaybookBlock`: Added `isBlurred` support. Renders overlay on tactical bullets.
- **Integration (`OnDemandPanel`):**
    - Defined `OnDemandTier` (Free/Plus/Elite).
    - Implemented `_resolveTier()` (Currently Free vs Elite).
    - Wired blur flags to widgets based on Tier.

## 3. Verification
- **Static Analysis:** Passed (`flutter analyze` clean).
- **Compilation:** Passed (`flutter build web`).
- **Logic:**
    - **Free User:** Sees Past Data (Clear), "Ghost" Future (Blurred), Tactical Details (Blurred).
    - **Elite User:** Sees All Clear.
- **Safety:** Past/Factual data is NEVER blocked.

## 4. Artifacts
Directory: `outputs/proofs/day47_hf30_blurred_truth_gating/`
- `00_diff.txt`
- `01_flutter_analyze.txt`
- `02_flutter_build_web.txt`
- `03_runtime_screenshots.png` (Skipped)
- `04_runtime_note.md`

## 5. Next Steps
- D48: BRAIN Activation.
