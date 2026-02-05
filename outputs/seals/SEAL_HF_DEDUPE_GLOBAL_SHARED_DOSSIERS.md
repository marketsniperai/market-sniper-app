# SEAL: HF-DEDUPE-GLOBAL SHARED DOSSIERS

**Date:** 2026-01-28
**Author:** Antigravity
**Authority:** D47.HF-DEDUPE-GLOBAL
**Status:** SEALED

## 1. Objective
Implement global shared dossier deduplication to reduce compute costs by serving public, non-personalized dossiers to multiple users.
Strategy: Filesystem-backed Global Cache at `outputs/on_demand_public/` (mapped to GCSFuse).

## 2. Changes
### New Modules
- [`backend/os_ops/global_cache_server.py`](../../backend/os_ops/global_cache_server.py): `GlobalCacheServer` class. Handles `public=True` metadata.

### Modifications
- [`backend/os_intel/projection_orchestrator.py`](../../backend/os_intel/projection_orchestrator.py): 
    - **Step 0:** Checks `GlobalCacheServer.get()` before Local Cache. Implements Read-Through (Global -> Local).
    - **Step 8:** Writes to `GlobalCacheServer.put()` (Write-Through).
- [`docs/canon/OS_MODULES.md`](../../docs/canon/OS_MODULES.md): Added `OS.OnDemand.Global`.
- [`os_registry.json`](../../os_registry.json): Registered `OS.OnDemand.Global`.

## 3. Verification
Script: [`backend/verify_hf_dedupe_global.py`](../../backend/verify_hf_dedupe_global.py)
Proof: [`outputs/proofs/hf_dedupe_global/02_runtime_note.md`](../../outputs/proofs/hf_dedupe_global/02_runtime_note.md)

### Results
- **Global Miss:** Computes and writes to Global Cache with `public=True`.
- **Global Hit:** Retrieves from Global Cache. Injects `source="GLOBAL_CACHE"`.
- **Safety:** Payload confirmed PII-free.
- **Efficiency:** Read-Through populates Local Cache instantly.

## 4. Repository Hygiene
All new files tracked.
Registry updated.
War Calendar updated.

## Pending Closure Hook
- Resolved Pending Items:
  - None
- New Pending Items:
  - None
