# Runtime Note: News Source Ladder

**Date:** D47.HF-A
**Component:** NewsEngine (Backend)

## Truth Ladder Behavior
The `/news_digest` endpoint tracks a strictly deterministic source ladder to ensure the downstream `ProjectionOrchestrator` never receives a 404 or missing inputs.

1.  **PIPELINE (Primary)**: Checks `outputs/engine/news_digest.json`. If valid (Status: EXISTING), returns it with `source: ARTIFACT_READ`.
2.  **DEMO (Fallback)**: If artifact is missing, generates a deterministic demo payload based on the current UTC date.
    -   Key: `demo-{YYYY-MM-DD}`
    -   Items include "Inflation", "Earnings", "Geopolitical" keywords to exercise `ContextTagger`.
    -   Returns with `source: DEMO_GENERATED`.
3.  **OFFLINE IMPACT**:
    -   The system no longer degrades to "NEWS_UNAVAILABLE" in `ProjectionOrchestrator`.
    -   Instead, it sees "AVAILABLE" and tags the demo content.

## Determinism
The Demo Generator is deterministic by Day. Repeated calls on the same day produce the same IDs and content, preventing "flicker" in the UI or Context Engine if the pipeline is offline.
