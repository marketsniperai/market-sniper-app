# SEAL: D49.ELITE.FIX.02 — Persistent Overlay above BottomNav

**Date:** 2026-01-29
**Author:** Antigravity (Agent)
**Status:** SEALED

## 1. Objectives & Resolution
The objective was to refactor the Elite Shell from a modal bottom sheet to a persistent overlay that remains open during tab navigation (`Dashboard`, `Watchlist`, `News`, etc.) and respects the Global Shell's layout.

### Resolutions
- **State Persistence:** Lifted Elite logic (`_isEliteOpen`, `_eliteExplainKey`, etc.) to `MainLayout`.
- **Layout Architecture:**
  - Implemented a `Stack` at the root of the `NotificationListener`.
  - **Base Layer:** `Safe Area > Column > [Top Bar, Expanded(Content), Bottom Nav]`.
  - **Overlay Layer:** `Positioned` Elite Shell anchored above the Bottom Nav (`bottom: 60`).
- **Interactive Hygiene:**
  - **Back Button:** `PopScope` intercepts back events to close Elite first.
  - **Menu Icon:** Toggles menu via overlay.
  - **Shield Icon:** Toggles Elite overlay.
- **Input Focus:** Input field remains active and focusable.

## 2. Verification Proofs
- **Static Analysis:** `flutter analyze` passed (MainLayout clean).
- **Compilation:** `flutter build web` PASSED (Exit Code 0).
- **Runtime Note:** `outputs/proofs/d49_elite_fix_02/05_runtime_note.md`.

## 3. Manifest of Changes
The following files were modified to achieve this state:
- `market_sniper_app/lib/layout/main_layout.dart` (Refactor to Stack/Overlay)
- `market_sniper_app/lib/widgets/elite_interaction_sheet.dart` (Added `onClose` callback)

## 4. Next Steps
- **D49.ELITE.LOGIC:** Full integration with backend logic.
