# SEAL: D47.HF32 ON-DEMAND COST POLICY (PER TICKER/DAY)

**Date:** 2026-01-28
**Author:** Antigravity
**Authority:** D47.HF32
**Status:** SEALED

## 1. Objective
Enforce "One Manual Computation Per Ticker Per Day (ET)" to maintain cost discipline while ensuring user always sees latest truth.

## 2. Changes
### New Modules
- [`backend/os_ops/computation_ledger.py`](../../backend/os_ops/computation_ledger.py): Tracks Last Compute Time (UTC) per Ticket/Timeframe.

### Modifications
- [`backend/os_intel/projection_orchestrator.py`](../../backend/os_intel/projection_orchestrator.py): 
    - Added Ledger Check.
    - If blocked: Falls back to `get_latest_for_day()` (Global -> Local).
    - If allowed: Computes and updates Ledger.
- [`backend/os_ops/hf_cache_server.py`](../../backend/os_ops/hf_cache_server.py): Added `get_latest_for_day()` logic.
- [`backend/os_ops/global_cache_server.py`](../../backend/os_ops/global_cache_server.py): Added `get_latest_for_day()` logic.
- [`market_sniper_app/lib/screens/on_demand_panel.dart`](../../market_sniper_app/lib/screens/on_demand_panel.dart): Added UI Banner for "policy_block".

## 3. Verification
### Logic Check
- **Enforcement:** Verified via scripts. Run 1 allows, Run 2 blocks.
- **Fallback:** Verified cache retrieval on block.
- **Safety:** Verified computation occurs if block logic triggers but no cache exists.

### Evidence
- **Proofs:** `outputs/proofs/hf32_cost_policy_on_demand/`
    - `00_diff.txt`
    - `02_sample_first_run.json`
    - `03_sample_second_run_policy_block.json`
    - `04_runtime_note.md`

## 4. Repository Hygiene
- No breaking changes to existing cache keys.
- No new external dependencies.

## Pending Closure Hook
- Resolved Pending Items:
  - None
- New Pending Items:
  - None
