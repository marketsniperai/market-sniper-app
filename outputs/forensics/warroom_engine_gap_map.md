# War Room Engine Gap Map

**Generated:** 2026-01-23
**Context:** POLISH.WARROOM.RESTORE.02
**Source Truth:** `docs/canon/legacy/B_VICTORY_CHECKLIST__RAW.md`

## Overview
This map identifies engines and surfaces that existed in the legacy victory checklist but are currently Missing, Stubbed, or Partial in the OMSR architecture. These items have been re-inserted into the War Calendar (Phase 4, D36.3+) for reconciliation.

## Engine Gaps

### [D36.3] Options Intelligence v1
- **Status:** STUB
- **Legacy Ref:** C2 — Options Intelligence
- **War Room Tile:** **REQUIRED**
- **Primary Artifact:** `outputs/engine/options_context.json`
- **Scope:** Descriptive options context (IV regime, skew, expected move). No signals.

### [D36.4] Evidence & Backtesting Engine v1
- **Status:** PARTIAL
- **Legacy Ref:** C3 — Backtest Real / B6 — Backtest Visual
- **War Room Tile:** **REQUIRED**
- **Primary Artifact:** `outputs/engine/evidence_summary.json`
- **Scope:** Regime-based historical matching. Sample size guards. No forecasting.

### [D36.5] Macro Layer v1
- **Status:** MISSING
- **Legacy Ref:** C2 — Macro Layer / B3 Context
- **War Room Tile:** **REQUIRED**
- **Primary Artifact:** `outputs/engine/macro_context.json`
- **Scope:** Macro context layer (Rates, USD, Oil) feeding Context Core. Graceful degrade.

### [D36.6] Lexicon Pro v1
- **Status:** MISSING
- **Legacy Ref:** B5 — Lenguaje Legal & Honesto
- **War Room Tile:** NO
- **Primary Artifact:** `config/lexicon_rules.json`
- **Scope:** Copy refinement and tone enforcement. Stealth sales engine. No red banners.

### [D36.7] Voice/TTS MVP Reconciliation
- **Status:** MISSING
- **Legacy Ref:** Legacy MVP
- **War Room Tile:** NO
- **Primary Artifact:** `outputs/engine/voice_state.json`
- **Scope:** Re-absorb legacy MVP references only. Not full Voice v2.

## Alignment Actions
1.  **War Calendar:** Updated D36.3–D36.7 with full operational descriptions.
2.  **War Room:** Future tasks must implement tiles for Options, Evidence, and Macro.
3.  **Governance:** These engines must adhere to `B_VICTORY_CHECKLIST` "Legal & Honesto" principles (Descriptive, not prescriptive).

