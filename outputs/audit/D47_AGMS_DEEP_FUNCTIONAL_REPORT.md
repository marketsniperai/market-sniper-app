# AGMS Deep Functional Report (Day 47)

**Auditor:** Antigravity  
**Date:** 2026-01-27  
**Scope:** Advanced Global Memory System (Backend Forensic Audit)

## 1. AGMS Module Map (Current Reality)

| Module | Responsibilities | Inputs | Outputs | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **AGMS Foundation** (`agms_foundation.py`) | **Memory & Mirror**. Observes runtime artifacts (manifests, locks) and records "Drift" (diff vs expectation). | `run_manifest.json`, `os_lock.json`, `autofix_status.json` | `agms_snapshot.json`, `agms_delta.json`, `agms_ledger.jsonl` | **Live**. Feeds Intelligence & War Room. |
| **AGMS Intelligence** (`agms_intelligence.py`) | **Pattern & Coherence**. Analyzes ledgers to compute a "Coherence Score" (0-100) and detect persistent patterns (e.g. frequent lock drift). | `agms_ledger.jsonl`, `autofix_ledger.jsonl` | `agms_patterns.json`, `agms_coherence_snapshot.json`, `agms_weekly_summary.json` | **Live**. Feeds Stability Bands & Thresholds. |
| **AGMS Dynamic Thresholds** (`agms_dynamic_thresholds.py`) | **Sensitivity Tuning**. Adjusts system constants (timeouts, limits) based on Coherence Score. | `agms_patterns.json`, `agms_coherence_snapshot.json` | `agms_dynamic_thresholds.json`, `agms_thresholds_ledger.jsonl` | **Live**. Consumed by War Room (Visibility) & potentially Logic Gates. |
| **AGMS Stability Bands** (`agms_stability_bands.py`) | **DEFCON Signaling**. Translates metrics into Green/Yellow/Orange/Red status. | All AGMS Artifacts | `agms_stability_band.json`, `agms_band_ledger.jsonl` | **Live**. Key indicator in War Room. |
| **AGMS Shadow Recommender** (`agms_shadow_recommender.py`) | **Action Proposal**. Maps patterns to specific Playbook IDs (e.g. "PB-MISFIRE"). | `agms_patterns.json` | `agms_shadow_suggestions.json`, `agms_shadow_ledger.jsonl` | **Shadow**. Suggestions generated but not auto-executed. |
| **AGMS Autopilot Handoff** (`agms_autopilot_handoff.py`) | **Execution Bridge**. Cryptographically signs safe suggestions for Autofix. | `agms_shadow_suggestions.json` | `agms_handoff.json`, `agms_handoff_ledger.jsonl` | **Active**. Generating tokens for Bridge. |
| **AGMS Stability Bands** (`agms_stability_bands.py`) | **DEFCON Signaling**. Translates metrics into Green/Yellow/Orange/Red status. | All AGMS Artifacts | `agms_stability_band.json`, `agms_band_ledger.jsonl` | **Live**. Key indicator in War Room. |

---

## 2. AGMS Artifact Truth Graph

| Artifact | Producer | Consumer(s) | Function | Status |
| :--- | :--- | :--- | :--- | :--- |
| `agms_snapshot.json` | Foundation | Intelligence, War Room | Raw State Observation | **LIVE** |
| `agms_ledger.jsonl` | Foundation | Intelligence | Historic Event Log | **LIVE** |
| `agms_patterns.json` | Intelligence | Thresholds, Bands, Shadow, Elite | Pattern Aggregation | **LIVE** |
| `agms_coherence_snapshot.json` | Intelligence | Thresholds, Bands, War Room | System Health Score | **LIVE** |
| `agms_dynamic_thresholds.json` | Thresholds | Bands, War Room | Sensitivity Config | **LIVE** |
| `agms_stability_band.json` | Stability Bands | War Room | Visual Alert Level | **LIVE** |
| `agms_shadow_suggestions.json` | Shadow Rec. | Autopilot Handoff, War Room | Proposed Actions | **LIVE** |
| `agms_handoff.json` | Autopilot | Autofix (Bridge), War Room | Signed Execution Permits | **LIVE** |

**Orphan Analysis:**
- **No Orphans Found**. Every AGMS artifact is part of a tight dependency chain ending in the War Room (Visibility) or Autofix (Action).

---

## 3. Overlap & Redundancy Analysis

### A. Iron OS vs AGMS Foundation ("The Two Mirrors")
- **Conflict**: Both systems "observe" the OS state.
  - `Iron OS` produces `os_state.json` (The "Official" Mirror used by Projection).
  - `AGMS Foundation` produces `agms_snapshot.json` (The "Internal" Mirror used by Intelligence).
- **Risk**: Low but present. If Iron OS says "LOCKED" but AGMS says "FREE", we have split-brain.
- **Mitigation**: AGMS should technically Consume `os_state.json` as its primary input for "State" rather than re-deriving it, OR Iron OS should be the single source of truth for "State" while AGMS focuses on "Drift" (Change over time). Currently they run parallel.

### B. Projection vs AGMS ("The Two Brains")
- **Status**: **Clean Separation**.
  - `Projection`: External Context (News/Macro/Options).
  - `AGMS`: Internal Context (Drift/Health/Patterns).
- **Recommendation**: Do not merge. Keep separate. One looks out, one looks in.

---

## 4. Update Feasibility Analysis (Calibration Scoreboard)

**Objective**: Track "Reliability", "Uptime", and "Calibration Accuracy" without a new module.

| Feature | New Module? | Feasibility | Implementation Path |
| :--- | :--- | :--- | :--- |
| **Reliability Metrics** | **NO** | High | Update `AGMSIntelligence`. It already parses the Ledger. Add logic to track `% NOMINAL` time. |
| **Projection Uptime** | **NO** | High | Update `AGMSFoundation` to observe `projection_report.json` state field. Log state changes to Ledger. AGMS Intel computes uptime. |
| **Scenario Hindsight** | **NO** | Medium | Update `AGMSIntelligence`. Compare historic `projection_report` (from backup/ledger) vs today's price. requires simple Price Ingestion or accessing `IntradaySeries`. |

**Verdict**: The "Reliability / Calibration Scoreboard" is a natural feature extension of **AGMS Intelligence**.

---

## 5. Safe Next Updates (AGMS ONLY)

**Scenario**: We want to add "Calibration Scoreboard" in Day 48.

**Plan (Update Only):**
1.  **Modify `AGMSFoundation`**: Add observation of `outputs/os/projection/projection_report.json`. Record `state` (OK/CALIBRATING) in the `agms_snapshot` and `agms_ledger`.
2.  **Modify `AGMSIntelligence`**:
    - Add `_compute_reliability_metrics(ledgers)` method.
    - Calculate `24h_uptime` and `calibration_rate` from the ledger data.
    - Append `reliability_metrics` struct to `agms_coherence_snapshot.json`.
3.  **Result**: War Room can immediately display these metrics by reading the updated Coherence artifact. **Zero new modules.**

---

**AUDIT CONCLUSION**: AGMS is a robust, well-structured "Internal Brain". It is safe to extend for Reliability/Calibration tracking. No architectural changes required.
