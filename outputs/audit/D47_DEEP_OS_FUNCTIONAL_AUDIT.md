# Deep OS Functional Audit (Day 47)

**Auditor:** Antigravity  
**Date:** 2026-01-27  
**Scope:** Full Functional Map, Artifact Truth, and Upgrade Feasibility.

## 1. Executive Summary
The MarketSniper OS (D47) exhibits a high degree of architectural coherence in its Core Intelligence (Options, Macro, Projection) and Operational (Iron OS, War Room) layers. However, a critical **"Ghost Dependency"** exists in the News Projection loop, where the Backend expects a `news_digest.json` artifact that has no producer. 

The frontend implementation of News (`NewsDigestSource.dart`) is currently isolated from the backend brain, creating a "Split Brain" risk where the UI shows news cards that the Projection Orchestrator cannot see.

**Key Findings:**
- **Solid**: Projection Orchestrator & On-Demand loop.
- **Critical Gap**: News Engine Backend (`outputs/engine/news_digest.json` is missing).
- **Update Opportunity**: AGMS Intelligence can be cheaply updated to provide the "Calibration Scoreboard" without a new module.

---

## 2. Global OS Functional Map

### A. Backend Intelligence (os_intel)
| Module | Inputs | Outputs | Triggers | Failure Mode | Consumers |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Projection Orchestrator** | `signals`, `options`, `macro`, `news` (missing) | `projection_report.json` | Pipeline / On-Demand | `INSUFFICIENT_DATA` | On-Demand API, Regime Sentinel |
| **Intraday Series** | Symbol, Vol Scale | `intraday_series_data` (internal) | On-Demand | Fallback to Ghost | Projection (Demo Series) |
| **AGMS Foundation** | Manifests, Lock, Autofix | `agms_snapshot.json`, `agms_ledger.jsonl` | Sched / Pipeline | `NO_OP` | War Room, Elite |
| **AGMS Intelligence** | `agms_ledger.jsonl` | `agms_patterns.json`, `agms_coherence.json` | Sched / Pipeline | `NO_OP` | War Room |
| **Context Tagger** | `engine/*` artifacts | In-Memory Tags | Projection Loop | Empty Tags | Projection Orchestrator |

### B. Backend Operations (os_ops)
| Module | Inputs | Outputs | Triggers | Failure Mode | Consumers |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Iron OS** | Artifacts (FS Scan) | `os_state.json` ("The Mirror") | Heartbeat / API | `OFFLINE` | System-wide Gates |
| **War Room** | Status Engines | `war_room_status.json` | API | `STALE` | War Room UI |
| **Housekeeper** | `os_housekeeper_plan.json` | Cleaned FS | Sched / API | `NO_OP` (Safety) | Logs |
| **On-Demand Cache** | Ticker Request | `on_demand_cache/` | API Hit | `BLOCK` (Tier/Limit) | Frontend |

### C. Frontend Consumers (market_sniper_app)
| Surface | Dependency | Gating Logic | Duplicate Risk |
| :--- | :--- | :--- | :--- |
| **Regime Sentinel** | `Projection Report` | `CALIBRATING` | **High**: `_GhostTracePainter` renders fallback waves locally. |
| **On-Demand Panel** | `Projection Report` | `TIER_LOCK`, `STALE` | Low: Consumes backend directly. |
| **News Screen** | `NewsDigestSource.dart` | `DEMO` | **Critical**: Backend has no visibility into this data. |
| **War Room** | `WarRoomStatus` | `DEGRADED` | Low: Pure reflection. |

---

## 3. Artifact Truth Graph

### The Core Loop (Healthy)
`options_engine.py` -> `options_context.json` -> `ProjectionOrchestrator` -> `projection_report.json` -> `RegimeSentinel`

### The Ghost (Broken)
`???` (Missing Producer) -> `news_digest.json` -> `ProjectionOrchestrator` -> `(News Unavailable)`

### The Isolated Limb
`NewsDigestSource.dart` -> `News UI` (Frontend Only)

**Impact**: Use of `ContextTagger.tag_news()` inside Projection is currently effectively dead code or stubbed because the artifact is missing, while the User sees news on the frontend. Logic split.

---

## 4. Overlap & Consolidation Recommendations

### A. News Engine Unification (High Priority)
**Update**: Migrate `NewsDigestSource` logic from Dart to Python (`backend/os_intel/news_engine.py`).
**Remove**: `NewsDigestSource.dart` (make it a dumb consumer of an API endpoint/artifact).
**Why**: Ensures `ProjectionOrchestrator` sees the same "Earnings Cluster" or "Macro Headlines" tags that the User sees on the cards. Alignment of Truth.

### B. Intraday Series Centralization (Medium)
**Update**: `RegimeSentinelWidget` should strictly render `IntradaySeriesSource` points.
**Remove**: `_GhostTracePainter` logic in Dart. The Backend should provide the "Ghost/Calibrating" points even in calibrating state if possible, or a dedicated "Calibrating Series".
**Why**: Single source of "Geometry".

### C. AGMS & Reliability (Low Risk)
**Update**: Consolidate "Reliability Metrics" into `AGMSIntelligence`.
**Avoid**: Creating `ReliabilityScoreboard` module.
**Why**: AGMS already owns "Coherence". Reliability is just a temporal dimension of Coherence.

---

## 5. AGMS Calibration Upgrade Proposal

The "Reliability / Calibration Scoreboard" should be implemented as an **UPDATE** to `backend/os_intel/agms_intelligence.py`.

### Schema Additions
In `agms_coherence_snapshot.json` (or a linked `agms_calibration.json`), add:

```json
"calibration_metrics": {
  "window_24h": {
    "total_minutes": 1440,
    "calibrating_minutes": 120,
    "live_minutes": 1320,
    "uptime_score": 91.6
  },
  "projection_accuracy": {
    "scenarios_generated": 45,
    "regime_matches": "N/A (Requires Future Hindsight)" 
  }
}
```

### Implementation Logic
1. **Source**: Read `projection_report.json` state field and `os_state.json` history.
2. **Logic**:
   - `AGMSIntelligence` already analyzes ledgers.
   - Simply track transitions of `ProjectionState` in `os_state.json` history.
   - Calculate `% Time in OK State`.
3. **Artifact**: Append to `agms_coherence`.

**Conclusion**: Do not build a new "Scoreboard Module". Upgrade AGMS Intelligence (Day 48+ task).
