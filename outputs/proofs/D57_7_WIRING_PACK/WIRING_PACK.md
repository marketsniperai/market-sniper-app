# MARKET SNIPER OS - FULL WIRING PACK
**Generated:** 2026-02-05T23:20:33.450300

## 1. Base URLs
- **Local:** `http://127.0.0.1:8787`
- **Prod (Discovered):**
  - `https://marketsniper-api-3ygzdvszba-uc.a.run.app`

## 2. Inventory & Classification
| Status | Method | Path |
|---|---|---|
| **DEPRECATED_ALIAS** | GET | `/agms/handoff` |
| **DEPRECATED_ALIAS** | GET,HEAD | `/health_ext` |
| **DEPRECATED_ALIAS** | GET | `/lab/healthz` |
| **DEPRECATED_ALIAS** | GET | `/lab/war-room` |
| **DEPRECATED_ALIAS** | GET | `/lab/warroom` |
| **LAB_INTERNAL** | POST | `/lab/autofix/execute` |
| **LAB_INTERNAL** | POST | `/lab/autopilot/execute_from_handoff` |
| **LAB_INTERNAL** | GET | `/lab/canon/debt_index` |
| **LAB_INTERNAL** | POST | `/lab/dojo/run` |
| **LAB_INTERNAL** | POST | `/lab/misfire_autoheal` |
| **LAB_INTERNAL** | GET | `/lab/os/health` |
| **LAB_INTERNAL** | POST | `/lab/os/housekeeper/run` |
| **LAB_INTERNAL** | GET | `/lab/os/housekeeper/status` |
| **LAB_INTERNAL** | GET | `/lab/os/iron/drift` |
| **LAB_INTERNAL** | GET | `/lab/os/iron/replay_integrity` |
| **LAB_INTERNAL** | GET | `/lab/os/iron/state_history` |
| **LAB_INTERNAL** | GET | `/lab/os/iron/status` |
| **LAB_INTERNAL** | GET | `/lab/os/iron/timeline_tail` |
| **LAB_INTERNAL** | POST | `/lab/os/rollback` |
| **LAB_INTERNAL** | GET | `/lab/os/self_heal/autofix/decision_path` |
| **LAB_INTERNAL** | POST | `/lab/os/self_heal/autofix/tier1/run` |
| **LAB_INTERNAL** | GET | `/lab/os/self_heal/autofix/tier1/status` |
| **LAB_INTERNAL** | GET | `/lab/os/self_heal/before_after` |
| **LAB_INTERNAL** | GET | `/lab/os/self_heal/findings` |
| **LAB_INTERNAL** | POST | `/lab/os/self_heal/housekeeper/run` |
| **LAB_INTERNAL** | GET | `/lab/os/self_heal/housekeeper/status` |
| **LAB_INTERNAL** | GET | `/lab/replay/archive/tail` |
| **LAB_INTERNAL** | POST | `/lab/replay/day` |
| **LAB_INTERNAL** | POST | `/lab/run_pipeline` |
| **LAB_INTERNAL** | POST | `/lab/shadow_repair/propose` |
| **LAB_INTERNAL** | POST | `/lab/tuning/apply` |
| **LAB_INTERNAL** | GET,HEAD | `/lab/war_room` |
| **LAB_INTERNAL** | GET | `/lab/war_room/snapshot` |
| **LAB_INTERNAL** | POST | `/lab/watchlist/log` |
| **LAB_INTERNAL** | GET | `/lab/watchlist/log/tail` |
| **PUBLIC_PRODUCT** | GET | `/aftermarket` |
| **PUBLIC_PRODUCT** | GET,HEAD | `/agms/foundation` |
| **PUBLIC_PRODUCT** | GET | `/briefing` |
| **PUBLIC_PRODUCT** | GET,HEAD | `/context` |
| **PUBLIC_PRODUCT** | GET,HEAD | `/dashboard` |
| **PUBLIC_PRODUCT** | GET | `/dashboard` |
| **PUBLIC_PRODUCT** | GET | `/healthz` |
| **PUBLIC_PRODUCT** | GET | `/lab/readyz` |
| **PUBLIC_PRODUCT** | GET | `/macro_context` |
| **PUBLIC_PRODUCT** | GET | `/news_digest` |
| **PUBLIC_PRODUCT** | GET | `/options_context` |
| **PUBLIC_PRODUCT** | GET | `/projection/report` |
| **PUBLIC_PRODUCT** | GET | `/pulse` |
| **PUBLIC_PRODUCT** | GET | `/readyz` |
| **UNKNOWN_ZOMBIE** | GET | `/agms/handoff/ledger/tail` |
| **UNKNOWN_ZOMBIE** | GET | `/agms/intelligence` |
| **UNKNOWN_ZOMBIE** | GET | `/agms/ledger/tail` |
| **UNKNOWN_ZOMBIE** | GET | `/agms/shadow/ledger/tail` |
| **UNKNOWN_ZOMBIE** | GET | `/agms/shadow/suggestions` |
| **UNKNOWN_ZOMBIE** | GET | `/agms/summary` |
| **UNKNOWN_ZOMBIE** | GET | `/agms/thresholds` |
| **UNKNOWN_ZOMBIE** | GET | `/autofix` |
| **UNKNOWN_ZOMBIE** | GET | `/blackbox/ledger/tail` |
| **UNKNOWN_ZOMBIE** | GET | `/blackbox/snapshots` |
| **UNKNOWN_ZOMBIE** | GET | `/blackbox/status` |
| **UNKNOWN_ZOMBIE** | GET | `/dojo/status` |
| **UNKNOWN_ZOMBIE** | GET | `/dojo/tail` |
| **UNKNOWN_ZOMBIE** | GET | `/economic_calendar` |
| **UNKNOWN_ZOMBIE** | GET | `/efficacy` |
| **UNKNOWN_ZOMBIE** | GET | `/elite/agms/recall` |
| **UNKNOWN_ZOMBIE** | POST | `/elite/chat` |
| **UNKNOWN_ZOMBIE** | GET | `/elite/context/status` |
| **UNKNOWN_ZOMBIE** | GET | `/elite/explain/status` |
| **UNKNOWN_ZOMBIE** | GET | `/elite/micro_briefing/open` |
| **UNKNOWN_ZOMBIE** | GET | `/elite/os/snapshot` |
| **UNKNOWN_ZOMBIE** | POST | `/elite/reflection` |
| **UNKNOWN_ZOMBIE** | GET | `/elite/ritual` |
| **UNKNOWN_ZOMBIE** | GET | `/elite/ritual/{ritual_id}` |
| **UNKNOWN_ZOMBIE** | GET | `/elite/script/first_interaction` |
| **UNKNOWN_ZOMBIE** | POST | `/elite/settings` |
| **UNKNOWN_ZOMBIE** | GET | `/elite/state` |
| **UNKNOWN_ZOMBIE** | GET | `/elite/what_changed` |
| **UNKNOWN_ZOMBIE** | GET | `/events/latest` |
| **UNKNOWN_ZOMBIE** | GET | `/events/latest` |
| **UNKNOWN_ZOMBIE** | GET | `/evidence_summary` |
| **UNKNOWN_ZOMBIE** | GET | `/immune/status` |
| **UNKNOWN_ZOMBIE** | GET | `/immune/tail` |
| **UNKNOWN_ZOMBIE** | GET | `/misfire` |
| **UNKNOWN_ZOMBIE** | GET | `/on_demand/context` |
| **UNKNOWN_ZOMBIE** | GET | `/options_report` |
| **UNKNOWN_ZOMBIE** | GET | `/os/state_snapshot` |
| **UNKNOWN_ZOMBIE** | GET | `/overlay_live` |
| **UNKNOWN_ZOMBIE** | GET | `/sunday_setup` |
| **UNKNOWN_ZOMBIE** | GET | `/tuning/status` |
| **UNKNOWN_ZOMBIE** | GET | `/tuning/tail` |
| **UNKNOWN_ZOMBIE** | GET | `/voice_state` |

## 3. Data Wiring
### Buckets
- `gs://...`
### Artifact Roots
- `outputs/`
### Critical Files
- `dashboard_market_sniper.json`
- `run_manifest.json`

## 4. Pipeline Wiring
### Jobs
- `pipeline_light`
- `run_pipeline`
### Entrypoints
- `main.py`
### Schedulers
- `generate_wiring_pack.py`