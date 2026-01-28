
# SEAL: D47.HF21 — On-Demand Projection Consume

**SEALED BY:** Antigravity  
**DATE:** 2026-01-27  
**TASK ID:** D47.HF21  
**APP VERSION:** D47.1+

## 1. Description
Integrated the `ProjectionOrchestrator` output ("Probabilistic Context") into the On-Demand Analysis panel. This feature allows the user to see the projection state (CALIBRATING, OK, etc.), scenarios (Base/Stress), and critical input statuses immediately after an on-demand analysis, without making directional predictions.

## 2. Changes
- **Backend:**
    - Updated `api_server.py:/on_demand/context` to inject `projection` report into the response envelope.
    - Fixed Pydantic deprecations in `watchlist_action_logger.py` (`regex` -> `pattern`).
    - Fixed dependencies in `on_demand_cache.py` (missing `timezone` import, syntax error).
- **Frontend:**
    - Updated `OnDemandPanel.dart` to include a "PROBABILISTIC CONTEXT" section.
    - Implemented `_buildProbabilisticContext` to render projection state and scenarios.
    - Enforced Signals-Free UI (no directional arrows, purely contextual).

## 3. Verification
- **Proof:** `verify_on_demand_projection_simple.py` successfully fetches `/on_demand/context` and confirms the presence of the `projection` field in the response.
- **Analysis:** `flutter analyze` passes across the frontend files with zero issues.
- **Hygiene:** Project Discipline Verifier run (pending strict hygiene cleanup).

## 4. Artifacts
- `backend/verify_on_demand_projection_simple.py`
- `outputs/proofs/day47_hf21_on_demand_projection_consume/06_simple_proof_final_v5.txt`
- `outputs/proofs/day47_hf21_on_demand_projection_consume/02_flutter_analyze_v2.txt`
