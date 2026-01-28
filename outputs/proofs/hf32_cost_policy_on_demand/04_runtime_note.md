# HF32 Runtime Note: Cost Policy (Per-Ticker Daily Run)

**Date:** 2026-01-28
**Context:** D47.HF32
**Status:** Verified

## 1. Policy Logic
- **Constraint:** One computation per Ticker per Timeframe per Day (ET).
- **Day Boundary:** 00:00 US/Eastern.
- **Enforcement:** `ComputationLedger` tracks `LastComputeTime`.

## 2. Fallback Logic (Source Ladder)
If blocked:
1. **Global Cache Fallback:** Scans `outputs/on_demand_public/TICKER/TIMEFRAME/` for *any* file from today.
2. **Local Cache Fallback:** Scans `outputs/cache/on_demand/` for *any* file matching today's prefix.
3. **Safety Fallback:** If NO cache exists (e.g. deleted), computation is ALLOWED to preserve truth.

## 3. Evidence
- **First Run:** Computed. Ledger Updated. (`02_sample_first_run.json`).
- **Second Run:** Blocked. Cache Served. (`03_sample_second_run_policy_block.json`).
- **Metadata:** `managed_by_policy="HF32_DAILY_LIMIT"`, `policy_block=True`.
- **UI:** Banner confirmed: "Already generated today. Showing latest cached dossier."

## 4. Ledger Location
`outputs/os/ledger/computation_ledger.json`
