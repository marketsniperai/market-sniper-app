# On-Demand Feature Audit Report
**Date:** 2026-01-27
**Scope:** Investigation of the On-Demand Feature (D44 Arc) Implementation
**Status:** READ-ONLY AUDIT

## 1. Executive Summary
The On-Demand feature is a mature, fully integrated analytical subsystem that bridges the gap between user-initiated requests and institutional market data. It implements a strict **Source Ladder** (Pipeline -> Cache -> Offline) and enforces **Tier Limits** (Free/Plus/Elite) with a "Business Day" reset at 04:00 ET.

The system is currently operating in a **Hybrid Offline/Cache Mode**, where valid pipeline artifacts are not yet fully integrated (Stubbed), falling back to offline or cached states.

## 2. Architecture & Data Flow

### Data Flow Ecosystem
1.  **Trigger**: User input (Ticker) or History Tap (Intent) -> `OnDemandPanel`.
2.  **Guard**: Frontend Regex Validation (`^[A-Z0-9._-]{1,12}$`).
3.  **Request**: `GET /on_demand/context?ticker=XYZ&tier=TIER`.
4.  **Enforcement (Backend)**:
    *   `OnDemandTierEnforcer` checks `outputs/os/os_on_demand_tier_limits.json`.
    *   Verifies Daily Quota and Cooldowns.
    *   Logs usage to `outputs/os/on_demand_usage_ledger.jsonl`.
    *   **Result**: Returns 429/403 if blocked, otherwise proceeds.
5.  **Resolution (Backend)**:
    *   `OnDemandCache.resolve_source` executes the Source Ladder:
        1.  **Pipeline Artifact**: (Stubbed - pending implementation).
        2.  **Cache Hit**: Checks `outputs/on_demand_cache/` (returns STALE if allowed).
        3.  **Offline Fallback**: Returns a valid `StandardEnvelope` with "OFFLINE" status.
6.  **Response**: API returns JSON with `_meta` (usage stats).
7.  **Rendering (Frontend)**:
    *   `EnvelopeBuilder` normalizes response.
    *   `LexiconSanitizer` guards against banned phrases.
    *   UI renders Header, Context Strip, and bullets.
    *   Success records ticker to `OnDemandHistoryStore` (Local).

## 3. Backend Implementation

### A. Tier Enforcement (`backend/os_ops/on_demand_tier_enforcer.py`)
*   **Logic**: Strict "check and log" atomic operation.
*   **Reset**: 04:00 ET (Approximated as UTC-5 for determinism).
*   **Ledger**: Append-only JSONL (`on_demand_usage_ledger.jsonl`).
*   **Limits**:
    *   **FREE**: 3/day (Locked in some policies).
    *   **PLUS**: 10/day, 10m Cooldown.
    *   **ELITE**: Unlimited, 5m Cooldown.
    *   **FOUNDER**: Bypass.

### B. Caching Engine (`backend/os_ops/on_demand_cache.py`)
*   **Storage**: Flat-file JSON in `outputs/on_demand_cache/`.
*   **Index**: `index.json` tracks metadata for FIFO eviction.
*   **Policy**: `outputs/os/os_on_demand_cache_policy.json` (Max 50 entries, TTLs vary by tier).
*   **Design**: Robust handling of missing files and corruption.

### C. API Layer (`backend/api_server.py`)
*   **Endpoint**: `/on_demand/context`
*   **Responsibility**: Orchestrates Enforcement -> Resolution -> Response.
*   **Metadata**: Injects `_meta` header for frontend Usage UI.

## 4. Frontend Implementation

### A. UI Panel (`lib/screens/on_demand_panel.dart`)
*   **State Management**: `idle` -> `loading` -> `result` | `error`.
*   **Intent System**: Listens to `NavigationBus` for `OnDemandIntent`. Supports `autoTrigger` (e.g., from Watchlist "Analyze") vs Prefill (History tap).
*   **Components**:
    *   `EnvelopePreviewHeader`: High-density Status/Source/Timestamp.
    *   `OnDemandContextStrip`: Visualizes Sector, Regime, Overlay, Pulse.
    *   `BadgeStripWidget`: Displays confidence badges.
    *   **"EXPLAIN" Button**: Dispatches `EliteExplainNotification`.

### B. Local History (`lib/logic/on_demand_history_store.dart`)
*   **Scope**: Last 5 unique tickers.
*   **Persistence**: Local JSON file via `path_provider`.
*   **Reset**: Syncs with 04:00 ET logic to clear history daily.

## 5. UX & Safety Mechanisms

*   **Stale Warning**: Visual Yellow Chip appears if data > 60m old or status is STALE.
*   **Lexicon Guard**: Client-side sanitizer ensures no "pump-and-dump" language reaches the user (`[SANITIZED]` tag).
*   **Feedback**: Real-time "Tier: X/Y Today" feedback loop driven by backend `_meta`.
*   **Input**: Enforces strictly uppercase alphanumeric ticker format.

## 6. Pending / Future Work

1.  **Pipeline Integration**: The Source Ladder currently skips the "Pipeline Artifact" step (Stubbed). Future work should integrate the standardized pipeline artifact reading.
2.  **Live Provider**: The "Offline Fallback" is valid but static. Connecting actual market data providers is the next logical engine step.
3.  **Time Sync**: Ensure Backend (UTC-5 approximation) and Frontend (Timezone lib) 04:00 ET reset logic remains perfectly synchronized to avoid "Ghost Limits".
