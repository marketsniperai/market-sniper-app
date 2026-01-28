# SEAL: HF-CACHE-SERVER (D47)

**Date:** 2026-01-28
**Author:** Antigravity
**Authority:** D47.HF-CACHE-SERVER
**Status:** SEALED

## 1. Objective
Implement server-side caching for `ProjectionOrchestrator` to reduce API costs and improve performance for On-Demand dossiers.
Strategy: Hourly buckets (`YYYYMMDD_HH`) per ticker/timeframe.

## 2. Changes
### New Modules
- [`backend/os_ops/hf_cache_server.py`](../../backend/os_ops/hf_cache_server.py): `OnDemandCacheServer` class (singleton).

### Modifications
- [`backend/os_intel/projection_orchestrator.py`](../../backend/os_intel/projection_orchestrator.py): Integrated `OnDemandCacheServer.get()` (start) and `.put()` (end). Checks `cache_hit` flag.
- [`docs/canon/OS_MODULES.md`](../../docs/canon/OS_MODULES.md): Added `OS.OnDemand.Cache`.
- [`os_registry.json`](../../os_registry.json): Registry entry.

### Fixes
- Resolved `NoneType` crash in `evidence_metrics` by ensuring default dict safety.

## 3. Verification
Script: [`backend/verify_hf_cache_server.py`](../../backend/verify_hf_cache_server.py)
Proof: [`outputs/proofs/hf_cache_server/verification.log`](../../outputs/proofs/hf_cache_server/verification.log)

### Results
- **Cache Miss:** First run fetches from source.
- **Cache Hit:** Second run fetches from disk (cache_hit=True).
- **Integrity:** Timestamps match source.
- **Payload:** Full `ProjectionOrchestrator` payload preserved.

## 4. Repository Hygiene
All new files tracked.
Trash cleaned (`inspect_orchestrator.py`, logs).
Registry updated.
