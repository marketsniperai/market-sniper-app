# PROJECTION ORCHESTRATOR READINESS AUDIT
**Date:** 2026-01-27
**Scope:** Backend, Frontend, Artifacts, Logic
**Status:** READ-ONLY / AUDIT

## 1. ENGINE / MODULE INVENTORY

### A. Intelligence / Analysis Layers

*   **Evidence Engine**
    *   **Location:** `backend/evidence_engine.py`
    *   **Type:** Evidence / Classification
    *   **Inputs:** Fingerprint (Regime, Trend, Vol - Stubbed)
    *   **Outputs:** `evidence_summary.json` (Summary, Diagnostics)
    *   **State:** STUB
    *   **Projection:** YES
    *   **Role:** Provides the "Base Case" historical match foundation.

*   **Options Engine**
    *   **Location:** `backend/options_engine.py`
    *   **Type:** UX / Surface / Context
    *   **Inputs:** Provider Snapshot (API), Cache
    *   **Outputs:** `options_context.json` (IV Regime, Skew, Expected Move)
    *   **State:** LIVE (Provider/Cache Fallback)
    *   **Projection:** YES
    *   **Role:** Provides "Expected Move" boundaries and Volatility Regime context.

*   **Macro Engine**
    *   **Location:** `backend/macro_engine.py`
    *   **Type:** Context
    *   **Inputs:** Stubbed Rates/Oil/Yields
    *   **Outputs:** `macro_context.json`
    *   **State:** STUB
    *   **Projection:** YES
    *   **Role:** Provides environment "weather" (Rate headwinds, Energy costs).

*   **AGMS Intelligence**
    *   **Location:** `backend/os_intel/agms_intelligence.py`
    *   **Type:** Supervisor / Intelligence
    *   **Inputs:** System State, Drift Scores
    *   **Outputs:** Coherence Analysis, Intelligence State
    *   **State:** LIVE
    *   **Projection:** INDIRECT
    *   **Role:** Validates if system state is coherent enough to trust a projection.

*   **AGMS Dynamic Thresholds**
    *   **Location:** `backend/os_intel/agms_dynamic_thresholds.py`
    *   **Type:** Safety / Gate
    *   **Inputs:** Market Volatility (Stub)
    *   **Outputs:** Sensitivity Config (High/Med/Low)
    *   **State:** LIVE
    *   **Projection:** YES
    *   **Role:** Determines confidence interval widths for projections.

### B. Operations / State Layers

*   **Iron OS**
    *   **Location:** `backend/os_ops/iron_os.py`
    *   **Type:** Memory / State
    *   **Inputs:** Events, Heartbeats
    *   **Outputs:** System Status, Ledger
    *   **State:** LIVE
    *   **Projection:** YES
    *   **Role:** Guarantees system integrity before running calculations.

*   **On-Demand Cache**
    *   **Location:** `backend/os_ops/on_demand_cache.py`
    *   **Type:** Memory
    *   **Inputs:** Ticker, Analysis Result
    *   **Outputs:** Cached JSON Artifacts
    *   **State:** LIVE
    *   **Projection:** YES
    *   **Role:** Stores previous projections/analysis to prevent re-calc drift.

*   **AGMS Foundation**
    *   **Location:** `backend/os_intel/agms_foundation.py`
    *   **Type:** Context / Truth Mirror
    *   **Inputs:** Runtime Artifacts
    *   **Outputs:** Snapshot, Ledger
    *   **State:** LIVE
    *   **Projection:** NO
    *   **Role:** Watches the watcher. Ensures artifact integrity.

### C. Logic / Frontend Layers

*   **Standard Envelope**
    *   **Location:** `lib/share/standard_envelope.dart`
    *   **Type:** Contract
    *   **Inputs:** N/A (Definition)
    *   **Outputs:** N/A
    *   **State:** LIVE
    *   **Projection:** YES
    *   **Role:** Defines the data structure that holds the projection payload.

*   **On-Demand History Store**
    *   **Location:** `lib/logic/on_demand_history_store.dart`
    *   **Type:** Memory
    *   **Inputs:** User Queries
    *   **Outputs:** JSON Persistence
    *   **State:** LIVE
    *   **Projection:** NO
    *   **Role:** User history context (non-critical).

---

## 2. CANDIDATE PROJECTION INPUTS (RAW)

### A) Market Structure / Regime
*   `Evidence Engine` (Fingerprint: Regime, Trend)
*   `On-Demand Pipeline` (Source Ladder: `resolve_source` prioritizes data quality)

### B) Historical Evidence / Memory
*   `On-Demand Cache` (Previous Ticker Analysis)
*   `Evidence Engine` (Historical Match Logic - Stubbed)

### C) Flow / Volatility / Options
*   `Options Engine` (IV Regime, Skew, Expected Move)
*   `Dynamic Thresholds` (Implied Volatility Sensitivity)

### D) News / Macro / Events
*   `Macro Engine` (Rates, Oil - Stubbed)
*   `Lexicon Pro Engine` (Narrative Refinement / Tone Safety)

### E) System State / Integrity / Gating
*   `Iron OS` (System Health)
*   `AGMS Intelligence` (Coherence)
*   `On-Demand Tier Enforcer` (Usage Limits / Entitlements)

---

## 3. EXISTING ARTIFACTS RELEVANT TO PROJECTION

*   **Evidence Summary**
    *   **Path:** `outputs/engine/evidence_summary.json`
    *   **Freshness:** On-Demand (Script Triggered)
    *   **Reliability:** STUB (Low)

*   **Options Context**
    *   **Path:** `outputs/engine/options_context.json`
    *   **Freshness:** On-Demand (Cached / Live)
    *   **Reliability:** SAFE (Live Provider w/ Cache)

*   **Macro Context**
    *   **Path:** `outputs/engine/macro_context.json` (Implied from engine)
    *   **Freshness:** Unknown (Likely Stub)
    *   **Reliability:** CONDITIONAL

*   **AGMS Snapshot**
    *   **Path:** `runtime/agms/agms_snapshot.json`
    *   **Freshness:** Periodic
    *   **Reliability:** SAFE

*   **On-Demand Source Ladder**
    *   **Path:** `outputs/os/os_on_demand_source_ladder.json`
    *   **Freshness:** Static Config
    *   **Reliability:** SAFE

---

## 4. CURRENT GAPS (FACTUAL ONLY)

*   **No Projection Orchestration Logic**: No "Brain" to combine Evidence + Options + Macro into a Price Target.
*   **No Scenario Schema**: "Base/Bear/Bull" structure is undefined in Backend schemas.
*   **No Intraday Price Series**: No engine produces or consumes 5m/1h candle arrays.
*   **No Stress Test Logic**: No logic to apply "-10%" or "Vol Spike" shocks to a holding.
*   **No Charting Engine**: Backend produces numbers, but no coordinates for a "Cone of Probability".

---

## 5. ORCHESTRATION READINESS SUMMARY

*   **Is OMSR already multi-engine capable for projection?**
    *   **YES**. The Modular Architecture (Ops vs Intel, Pipeline Controller) supports plugging in a `ProjectionEngine` that consumes outputs from `OptionsEngine` and `EvidenceEngine`.

*   **What % of projection intelligence already exists conceptually?**
    *   **~40%**. We have the "Limbs" (Options, Evidence, Macro stubs) and the "Nervous System" (Pipeline, AGMS), but we lack the "Prefrontal Cortex" (The Projection Orchestrator itself).

*   **Which engines are mandatory for v0?**
    *   `Evidence Engine` (Must be un-stubbed or fed real data).
    *   `Options Engine` (Live).
    *   `Projection Orchestrator` (NEW - The Mixer).

*   **Which are optional / enhancement-only?**
    *   `Macro Engine` (Can remain Stub/Neutral for v0).
    *   `Lexicon Pro` (Tone is nice, but not math-critical).
    *   `AGMS Shadow Recommender` (Advanced context, not needed for raw numbers).
