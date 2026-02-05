# PENDING LEDGER (CANON DEBT PURGE)

**Authority:** CANONICAL
**Sync Date:** Day 45
**Status:** ACTIVE
**Validation:** `verify_project_discipline.py`

This ledger is the **Single Source of Truth** for all "Planned", "Future", "Pending", and "Debt" items detected in the repository.
Items here are **NOT** bugs; they are distinct units of future value or technical debt to be serviced.

## 0. Lifecycle Rules (Canon)
1. **No Deletion**: Pending items are never deleted, only transitioned.
2. **Active Debt**: Status `OPEN` or `IN_PROGRESS`.
3. **Resolution**: Status `RESOLVED` requires `Resolved By Seal` and `Resolved At UTC`.
4. **Schema**: All items must follow the Key-Value list format below.
5. **Closure Hook**: All Seals must include `## Pending Closure Hook` declaring resolved items or "None".

## 1. Strategic Roadmap (War Calendar)

### PEND_INTEL_VOICE_V2
- **Module**: INTEL
- **Description**: D35: The Voice v2 (Full Voice Engine). End-to-end ritual, personalization, caching, governance.
- **Origin**: OMSR_WAR_CALENDAR (D35)
- **Trigger**: Phase 4 Closure
- **Status**: OPEN
- **Impact Area**: UX, Reliability
- **Estimated Effort**: L

### PEND_MSK_RISK_LANES
- **Module**: MSK
- **Description**: D46.01: Kernel Risk Lanes. Define READ-ONLY, WRITE-SAFE, FOUNDER-HIGH-PRIV, NETWORK lanes.
- **Origin**: OMSR_WAR_CALENDAR (D46.01)
- **Trigger**: Day 46 Start
- **Status**: OPEN

### PEND_MSK_PROC_RECEIPT
- **Module**: MSK
- **Description**: D46.02: Procedure Planner Receipt. Emit `os_kernel_receipt.json` after procedures.
- **Origin**: OMSR_WAR_CALENDAR (D46.02)
- **Trigger**: Day 46 Start
- **Status**: OPEN

### PEND_MSK_ABUSE_SCORE
- **Module**: MSK
- **Description**: D46.03: Intent-Aware AbuseScore. No-ML scoring of request patterns.
- **Origin**: OMSR_WAR_CALENDAR (D46.03)
- **Trigger**: Day 46 Start
- **Status**: OPEN

### PEND_MSK_GLOBAL_LOCK
- **Module**: MSK
- **Description**: D46.04: Global Execution Lock. Prevent concurrent hazards (e.g. Housekeeper vs Autofix).
- **Origin**: OMSR_WAR_CALENDAR (D46.04)
- **Trigger**: Day 46 Start
- **Status**: OPEN

## 2. Feature Stubs & Deferred Scope

### PEND_UI_OPTIONS_L3
- **Module**: UI
- **Description**: Flow Concentration (Context-only). Aggregated premium snapshot (Tenor/Side).
- **Origin**: SEAL_DAY_45_15 (Command Center)
- **Trigger**: Data Availability
- **Status**: OPEN

### PEND_INTEL_PROJECTION_LANE_EVIDENCE_ARTIFACT
- **Module**: INTEL.VOLUME
- **Description**: Probabilistic context model for +15m..+60m projection lane. Currently in CALIBRATING state.
- **Origin**: D45.HF10G.VOLUME_INTEL.TIMELINE
- **Trigger**: Model Availability
- **Status**: OPEN

### PEND_BACK_VOICE_MVP
- **Module**: BACKEND
- **Description**: Legacy Voice MVP stubbed in `voice_mvp_engine.py`. Needs full implementation.
- **Origin**: backend/voice_mvp_engine.py
- **Trigger**: PEND_INTEL_VOICE_V2
- **Status**: OPEN

###- [ ] PEND_INTEL_REGIME_SENTINEL_EVIDENCE_ARTIFACT (Evidence Schema)
- [ ] PEND_DATA_INTRADAY_5M_PROVIDER (High-Res Data Source)_BOOTSTRAP
- [ ] PEND_INTEL_CALENDAR_PROVIDER (Economic Calendar Real-Time Feed)_BOOTSTRAP

### PEND_INFRA_PROVIDER_APIS_BOOTSTRAP
- **Module**: OS.DATA
- **Description**: No provider APIs integrated yet; any provider-live surfaces must remain N/A/Replay/CALIBRATING until provider integration sprint is sealed.
- **Origin**: Day 45 Founder Note
- **Trigger**: UI Copy
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D48_BRAIN_05_PROVIDER_DATAMUX_V1.md
- **Evidence**: backend/os_data/datamux.py
- **Impact Area**: Reliability, UX, Governance

### PEND_UI_WATCHLIST_MSG
- **Module**: UI
- **Description**: Hardcoded string "Extended Universe unlocks in D39.02" in `watchlist_add_modal.dart`.
- **Origin**: lib/widgets/watchlist_add_modal.dart
- **Trigger**: Cleanup Polish
- **Status**: OPEN

### PEND_UI_SESSION_LOGIC
- **Module**: UI
- **Description**: Weekend logic comment "Days until Mon = 7; Should be handled but explicit safety".
- **Origin**: lib/widgets/session_awareness_panel.dart
- **Trigger**: Robustness Audit
- **Status**: OPEN

## 3. Tech Debt & Optimization

### PEND_REGISTRY_PATH
- **Module**: OPS
- **Description**: `verify_day_26_registry.py` flag: Check if PATH part starts with /.
- **Origin**: backend/verify_day_26_registry.py
- **Trigger**: Registry Audit
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D48_OPS_PEND_REGISTRY_PATH.md
- **Evidence**: outputs/proofs/d48_ops_pend_registry_path/02_after_pass.txt

### PEND_INTEL_SECTOR_SPIKE_BASELINE
- **Module**: INTEL.SECTOR
- **Description**: Sector Sentinel spike baseline upgrade to median(13).
- **Origin**: SEAL_D45_SECTOR_SENTINEL_RT_V0.md
- **Trigger**: D45 Closure
- **Status**: OPEN

### PEND_OPS_FLUTTER_ANALYZE_BASELINE_CLEANUP
- **Module**: OPS.FRONTEND
- **Description**: Flutter analyze baseline currently ~170+ issues (lints/style/null-safety). Non-blocking in building phase but required for release polish. Dedicated cleanup sprint needed to reduce noise and prevent future regressions.
- **Origin**: Day 45 Governance Note
- **Trigger**: Release Polish
- **Status**: OPEN

## 4. Pending Auth / Infra (HF08+)

### PEND_INFRA_API_GATEWAY_DEPLOY
- **Module**: OS.INFRA
- **Description**: Provision API Gateway + API Key to front Private Cloud Run.
- **Origin**: D45.HF05.AUTH.GATEWAY
- **Trigger**: Deployment Script Run
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D55_3_LB_WEB_UNBLOCK.md
- **Evidence**: GCP Load Balancer `34.36.210.87`
- **Method**: Global HTTPS LB + Serverless NEG (Replaces API Gateway)


### PEND_AUTH_FIREBASE_FULL
- **Module**: OS.AUTH
- **Description**: Migrate from API Key (Route B) to Firebase JWT (Route A) for public clients.
- **Origin**: D45.HF05.AUTH.GATEWAY
- **Trigger**: Security Hardening
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D55_6_FIREBASE_HOSTING_REWRITE_UNBLOCK.md
- **Evidence**: `firebase.json` rewrite configuration
- **Method**: Managed Service Account (`firebase-hosting-sa`) with `roles/run.invoker`


## 5. Audit Fixes (D47.FIX)

### PEND_FIX_NEWS_UNIFICATION
- **Module**: INTEL.NEWS
- **Description**: D47.FIX.01: News Backend Unification. Resolve "Ghost Dependency" split brain.
- **Origin**: OMSR_WAR_CALENDAR (D47.FIX.01)
- **Trigger**: Day 47 Post-Audit
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D47_HF_A_NEWS_BACKEND_UNIFICATION.md

### PEND_FIX_AGMS_RELIABILITY
- **Module**: AGMS
- **Description**: D47.FIX.02: AGMS Reliability Scoreboard. Track Projection Uptime/Accuracy.
- **Origin**: OMSR_WAR_CALENDAR (D47.FIX.02)
- **Trigger**: Day 47 Post-Audit
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D47_FIX_02_AGMS_RELIABILITY_SCOREBOARD.md

## 6. Brains Inevitables (D48.BRAIN)

### PEND_BRAIN_SCHEMA_AUTHORITY
- **Module**: GOV
- **Description**: D48.BRAIN.01: Centralized JSON Schema Authority.
- **Origin**: OMSR_WAR_CALENDAR (D48.BRAIN.01)
- **Trigger**: Maturity Check
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D48_BRAIN_01_SCHEMA_AUTHORITY_V1.md

### PEND_BRAIN_ATTRIBUTION
- **Module**: INTEL
- **Description**: D48.BRAIN.02: Attribution Engine. Chain-of-Thought explainability.
- **Origin**: OMSR_WAR_CALENDAR (D48.BRAIN.02)
- **Trigger**: Maturity Check
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D48_BRAIN_02_ATTRIBUTION_ENGINE_V1.md

### PEND_BRAIN_SURFACE_ADAPTERS
- **Module**: UI
- **Description**: D48.BRAIN.03: Surface Adapters. Standardized JSON->Widget mapping.
- **Origin**: OMSR_WAR_CALENDAR (D48.BRAIN.03)
- **Trigger**: Maturity Check
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D48_BRAIN_03_SURFACE_ADAPTERS_V1_ON_DEMAND.md

### PEND_BRAIN_RELIABILITY_LEDGER
- **Module**: GOV
- **Description**: D48.BRAIN.04: Reliability Ledger. Calibration & Trust tracking.
- **Origin**: OMSR_WAR_CALENDAR (D48.BRAIN.04)
- **Trigger**: Maturity Check
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D48_BRAIN_04_RELIABILITY_LEDGER_GLOBAL_TRUTH.md

### PEND_BRAIN_DATAMUX
- **Module**: DATA
- **Description**: D48.BRAIN.05: Provider DataMux. Multi-provider abstraction.
- **Origin**: OMSR_WAR_CALENDAR (D48.BRAIN.05)
- **Trigger**: Scaling
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D48_BRAIN_05_PROVIDER_DATAMUX_V1.md

### PEND_BRAIN_EVENT_ROUTER
- **Module**: OPS
- **Description**: D48.BRAIN.06: Event Router. Centralized event bus.
- **Origin**: OMSR_WAR_CALENDAR (D48.BRAIN.06)
- **Trigger**: Real-Time Needs
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D48_BRAIN_06_EVENT_ROUTER_V1.md

### PEND_BRAIN_SCENARIO
- **Module**: TEST
- **Description**: D48.BRAIN.07: Scenario Library. Pre-canned "Deep Dreaming" states.
- **Origin**: OMSR_WAR_CALENDAR (D48.BRAIN.07)
- **Trigger**: Validation Needs
- **Status**: OPEN

### PEND_BRAIN_LLM_BOUNDARY
- **Module**: OPS
- **Description**: D48.BRAIN.08: LLM Boundary Wrapper. Cost guard & PII scrub.
- **Origin**: OMSR_WAR_CALENDAR (D48.BRAIN.08)
- **Trigger**: LLM Integration
- **Status**: RESOLVED
- **Resolved By Seal**: SEAL_D49_ELITE_AREA_SEALED_CANON_SYNC.md

