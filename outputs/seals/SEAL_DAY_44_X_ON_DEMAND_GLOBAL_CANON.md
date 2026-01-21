# SEAL: D44.X - On-Demand Global Canon

**Date:** 2026-01-19
**Author:** Antigravity (Agent)
**Status:** SEALED

## Canon
- **Universe Agnostic:** Removed `Core20` guard. Ticker validation is now purely regex (`^[A-Z0-9._-]{1,12}$`).
- **Source Ladder:** SSOT `os_on_demand_source_ladder.json`. Order: Pipeline -> Cache -> Offline.
- **Tier Policy:** SSOT `os_on_demand_tier_limits.json`. 
    - **Free:** Blocked (Limit 0).
    - **Plus:** 10/day, 10m Cooldown.
    - **Elite:** Unlimited, 5m Cooldown.
    - **Reset:** 04:00 ET.

## Implementation
- **Backend:** 
    - `on_demand_tier_enforcer.py` enforces Cooldowns and Zero-Limits.
    - `on_demand_cache.py` implements Source Ladder logic.
    - `api_server.py` handles 5-tuple enforcer return and Source Ladder resolution.
- **Frontend:**
    - `OnDemandPanel` displays Global Tickers.
    - New Badges: Source, Freshness, Usage.
    - Handling for Blocked Tiers and Cooldowns.

## Verification
- **Discipline:** Passed.
- **Analyzer:** Clean.
- **Proof:** `day_44_x_on_demand_global_guard_cache_tiers_proof.json`

## Scope
Completes the transition of On-Demand to a global, tiered, cost-controlled feature ready for future data provider integration.
