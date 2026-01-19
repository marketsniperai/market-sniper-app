# SEAL: D44.06 - Tier Limits + Counters

**Date:** 2026-01-19
**Author:** Antigravity (Agent)
**Verification Status:** VERIFIED (Automated)

## Implementation
1. **Policy**: `outputs/os/os_on_demand_tier_limits.json` defines limits and reset time (04:00 ET).
2. **Backend**: `on_demand_tier_enforcer.py` calculates timezone-aware buckets and enforces limits via `on_demand_usage_ledger.jsonl`.
3. **API**: `api_server.py` blocks excessive requests (HTTP 429) and returns usage metadata.
4. **Frontend**: `OnDemandPanel` displays usage counters ("X/Y Today") and handles blockade states.

## Metadata
- **Risk**: TIER_1 (Access Control).
- **Reset**: 04:00 US/Eastern.
- **Limits**: Free (3), Plus (10), Elite (Unlimited).
- **Legality**: Founder keys bypass all limits.
