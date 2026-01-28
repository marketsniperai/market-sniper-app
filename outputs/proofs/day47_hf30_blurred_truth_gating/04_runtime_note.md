# Runtime Verification Note
**Feature:** HF30 — Blurred Truth Gating (UI-Only V1)
**Date:** 2026-01-28

## Verification Context
Headless environment. Verification relies on static analysis and logic review.

## Logic Verification
1.  **Tier Logic (`OnDemandPanel`):**
    - `_resolveTier()` currently maps `_isEliteUnlocked` (true) -> `OnDemandTier.elite` and (false) -> `OnDemandTier.free`.
    - Plus Tier is defined but inactive (defaults to Free).
2.  **UI Components:**
    - `BlurredTruthOverlay`: Implemented with `BackdropFilter` (sigma 6.0) and "UNLOCK" CTA.
    - `TimeTravellerChart`: Accepts `blurFuture`. If true, overlays the future section (right of 66% width) with blur.
    - `TacticalPlaybookBlock`: Accepts `isBlurred`. If true, overlays the content bullets with blur.
3.  **Integration:**
    - Free Users see: Past Data (Clear), Future/Ghost (Blurred), Tactical Details (Blurred).
    - Elite Users see: All Clear.
    - Past data is NEVER blocked.

## Verification Artifacts
- **Analysis:** `01_flutter_analyze.txt` (Passed).
- **Build:** `02_flutter_build_web.txt` (Passed).
- **Screenshots:** Skipped (Headless).
- **Diff:** `00_diff.txt`.

## UX Note
The blur effect uses `Stack` + `Positioned.fill` ensuring headers remain visible (in Playbook) or context is preserved (in Chart), driving "Institutional Envy" without blocking the user's view of what they *could* have.
