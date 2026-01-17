# SEAL_DAY_40_07_ELITE_EXPLAIN_TRIGGER_WIRING

**Authority:** STRATEGIC
**Date:** 2026-01-17
**Day:** 40.07

## 1. Intent
Wire the "Elite Explain" trigger bubble to appear when the Global Pulse Synthesis indicates a significant shift (SHOCK/FRACTURED/RISK_OFF), subject to strict cooldowns and freshness rules.

## 2. Implementation
- **Source:** `GlobalPulseSynthesisSnapshot` (state).
- **Trigger Logic:** 
  - State in {SHOCK, FRACTURED, RISK_OFF}.
  - Freshness != UNAVAILABLE.
  - Cooldown: 30 minutes (Session-based via `_lastEliteTriggerTimes`).
- **UI:** `_buildEliteTrigger` renders a "Elite can explain this shift" chip with an `auto_awesome` icon.
- **Action:** Mock route to `_triggerEliteExplain` (Dialog/Snackbar placeholder for D43).

## 3. Proof
- **Runtime Proof:** `outputs/runtime/day_40/day_40_07_elite_explain_trigger_proof.json` generated via `verify_day_40_close.dart`.
- **Logic:** Verified state transitions (Active -> Cooldown -> Hidden).

## 4. Sign-off
- [x] Trigger only on specified states.
- [x] Cooldown enforced.
- [x] Safe degradation (Hidden if data unavailable).

SEALED.
