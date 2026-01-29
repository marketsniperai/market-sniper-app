# Runtime Note: Attribution Engine V1 (D48.BRAIN.02)

## Architecture
Implemented a deterministic **Attribution Engine** that injects "Chain-of-Thought" metadata into every On-Demand Projection.
- **Backend:** `ProjectionOrchestrator` now constructs an `attribution` object containing inputs consulted, rules fired, facts derived, and active blur policies.
- **Legacy Support:** Safely injects default attribution for Cached artifacts generated before this upgrade (schema migration at read-time).
- **Frontend:** New `AttributionSheet` widget displays this data, filtering "Active Restrictions" based on the user's Tier (Elite sees no restrictions).

## Verification
- **Backend Logic:** Validated via `verify_d48_attribution_v1.py` (In-Process). Confirmed payload structure and policy injection.
- **Frontend Safety:** `flutter analyze` confirms token compliance (AppColors/AppTypography) and type safety.
- **User Experience:**
  - Free/Plus users see *why* specific data is blurred (e.g., "TierGate: Future Projection restricted to Elite").
  - Elite users see "No active restrictions".

## Key Decisions
- **Source Ladder Transparency:** Explicitly flagging `GLOBAL_CACHE` vs `PIPELINE` allows users to trust the freshness and origin of data.
- **Static Rules:** Blur reasons are static policies, ensuring deterministic explanation regardless of day-to-day market variation.
