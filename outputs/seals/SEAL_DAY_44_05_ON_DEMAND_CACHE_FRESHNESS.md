# SEAL: D44.05 - On-Demand Cache + Freshness

**Date:** 2026-01-19
**Author:** Antigravity (Agent)
**Verification Status:** VERIFIED (Automated)

## Implementation
1. **SSOT Policy**: `outputs/os/os_on_demand_cache_policy.json` defines TTLs and Bounds.
2. **Backend Engine**: `on_demand_cache.py` implements a disciplined, file-based cache with index and payload files.
3. **Freshness Logic**: 
   - HIT: Return cached payload if `now < expires`.
   - STALE: Return cached if `allow_stale=true` (client opt-in).
   - MISS/EXPIRED: Fetch fresh from `EliteOSReader`, cache it, return `LIVE`.
4. **Lifecycle**: 
   - `OnDemandPanel` requests context -> API checks cache -> returns result.
   - UI displays Source (CACHE/LIVE) and Freshness (LIVE/STALE).

## Metadata
- **Risk**: TIER_1 (Safe Read-Only)
- **Bounds**: 50 Entries / 500KB Total.
- **Reversibility**: High (Delete cache folder).
