# SEAL_DAY_43_07_EXPLAIN_BUTTONS_WIRING

**Task:** D43.07 — “?” Buttons Wiring → Explain Router
**Date:** 2026-01-19
**Status:** SEALED (PASS)
**Proof:** `outputs/proofs/day_43/day_43_07_explain_buttons_wiring_proof.json`

## 1. Description
Wired "?" icon buttons to key dashboard widgets to trigger the Elite Explain Router via the canonical Status/Overlay shell.
- **Widgets:** Market Regime (DeltaCard), Pulse/Confidence (DeltaCard), Universe/Overlay (StatusCard).
- **Mechanism:** `EliteExplainNotification` bubbles up from widgets to `MainLayout`, which opens `EliteInteractionSheet` with `initialExplainKey`.
- **UI:** subtle `help_outline` icon in top-right of cards.
- **Tier Gating:** Mocked in `EliteInteractionSheet` (Free limited to MARKET_REGIME).

## 2. Changes
- `market_sniper_app/lib/logic/elite_messages.dart`: New notification class.
- `market_sniper_app/lib/layout/main_layout.dart`: Listener layout wrapper.
- `market_sniper_app/lib/widgets/dashboard_widgets.dart`: Added buttons to cards based on title keywords.
- `market_sniper_app/lib/widgets/elite_interaction_sheet.dart`: Handling of `initialExplainKey` and context display.

## 3. Verification
- `flutter analyze` passed (excluding legacy issues).
- `verify_project_discipline.py` passed.
- Proof artifact generated.

## 4. Canon Updates
- `OMSR_WAR_CALENDAR__35_45_DAYS.md`: Marked D43.07 [x].
- `PROJECT_STATE.md`: Logged D43.07.
