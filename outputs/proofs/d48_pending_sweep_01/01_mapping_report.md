# Pending Mapping Report (D48.BRAIN Sweep)

## A. READY TO CLOSE
These items have been implemented and sealed in today's D48.BRAIN arc.

| ID | Description | Resolution Seal | Evidence |
| :--- | :--- | :--- | :--- |
| **PEND_BRAIN_ATTRIBUTION** | D48.BRAIN.02 Attribution Engine | `SEAL_D48_BRAIN_02_ATTRIBUTION_ENGINE_V1.md` | `backend/os_intel/attribution_engine.py`, `outputs/ledgers/attribution_ledger.jsonl` |
| **PEND_BRAIN_SURFACE_ADAPTERS** | D48.BRAIN.03 Surface Adapters | `SEAL_D48_BRAIN_03_SURFACE_ADAPTERS_V1_ON_DEMAND.md` | `lib/adapters/on_demand/*.dart` |
| **PEND_BRAIN_RELIABILITY_LEDGER** | D48.BRAIN.04 Reliability Ledger | `SEAL_D48_BRAIN_04_RELIABILITY_LEDGER_GLOBAL_TRUTH.md` | `backend/os_ops/reliability_ledger_global.py` |
| **PEND_BRAIN_DATAMUX** | D48.BRAIN.05 Provider DataMux | `SEAL_D48_BRAIN_05_PROVIDER_DATAMUX_V1.md` | `backend/os_data/datamux.py` |
| **PEND_BRAIN_EVENT_ROUTER** | D48.BRAIN.06 Event Router | `SEAL_D48_BRAIN_06_EVENT_ROUTER_V1.md` | `backend/os_ops/event_router.py` |
| **PEND_INFRA_PROVIDER_APIS_BOOTSTRAP** | No provider APIs integrated yet | `SEAL_D48_BRAIN_05_PROVIDER_DATAMUX_V1.md` | DataMux V1 + `provider_config.json` |

## B. ALREADY RESOLVED (Double Check)
| ID | Status | Note |
| :--- | :--- | :--- |
| **PEND_BRAIN_SCHEMA_AUTHORITY** | RESOLVED | D48.BRAIN.01 Sealed previously. |
| **PEND_FIX_NEWS_UNIFICATION** | RESOLVED | D47.FIX.01 Sealed previously. |
| **PEND_FIX_AGMS_RELIABILITY** | RESOLVED | D47.FIX.02 Sealed previously. |

## C. STILL OPEN (Out of Scope for D48.BRAIN.01-06)
- **PEND_INTEL_VOICE_V2** (D35)
- **PEND_MSK_*** (D46.01-04)
- **PEND_UI_OPTIONS_L3** (D45)
- **PEND_INTEL_PROJECTION_LANE_EVIDENCE_ARTIFACT** (Intel)
- **PEND_BACK_VOICE_MVP** (Backend)
- **PEND_UI_WATCHLIST_MSG** (UI Polish)
- **PEND_UI_SESSION_LOGIC** (UI Polish)
- **PEND_REGISTRY_PATH** (Ops)
- **PEND_INTEL_SECTOR_SPIKE_BASELINE** (Intel)
- **PEND_OPS_FLUTTER_ANALYZE_BASELINE_CLEANUP** (Ops)
- **PEND_INFRA_API_GATEWAY_DEPLOY** (Infra)
- **PEND_AUTH_FIREBASE_FULL** (Auth)
- **PEND_BRAIN_SCENARIO** (D48.BRAIN.07)
- **PEND_BRAIN_LLM_BOUNDARY** (D48.BRAIN.08)

## D. DECISIONS
- **PEND_INFRA_PROVIDER_APIS_BOOTSTRAP**: Closing as RESOLVED by `D48.BRAIN.05`. The requirement was "until provider integration sprint is sealed". D48.BRAIN.05 is that sprint (V1 scaffolding).
