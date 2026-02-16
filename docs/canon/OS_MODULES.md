# OS MODULES INVENTORY (Canon)

**Authority:** IMMUTABLE
**Version:** 4.1 (Day 63 - Exact Count Audit)
**Exact Count:** 89 Modules

> **Days vs Modules**: "Days" represent the history of seals (time). "Modules" represent the operable units of the system (space).

## System Graph

### Operations Chain (The Body)
`Misfire Monitor` → `AutoFix Control Plane` → `Autopilot Policy Engine` → `Execution`
`Housekeeper` → `War Room` (Observer) → `Iron OS` (State)

### AGMS Intelligence Chain (The Mind)
`AGMS Foundation` → `AGMS Intelligence` → `Shadow Recommender` → `Autopilot Handoff`
`Dynamic Thresholds` ↔ `Confidence Bands` → `Evidence` → `Options` → `Macro`
`News` → `Calendar` → `Projection` (Fusion) → `Attribution` (Show Work)

### Elite Arc (The Voice)
`Elite Context` → `Explain Router` → `Interactive Shell`

---

## 1. Core & Infrastructure Layer

| Module ID | Name | Type | Description | Key Port (Endpoint) | Primary File | Seal Ref |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **OS.Infra.API** | API Server | CORE | Entry point for all system interactions. | `/*` | `backend/api_server.py` | Day 00 |
| **OS.Infra.Gates** | Core Gates | CORE | Enforces system safety and data freshness. | (Internal) | `backend/gates/core_gates.py` | Day 03 |
| **OS.Infra.CloudRun** | Cloud Run API | INFRA | Core Compute (Procfile + Lab Probes). | `marketsniper-api` | `backend/api_server.py` | Day 54 |
| **OS.Infra.LB** | Global Load Balancer | INFRA | HTTPS termination + Serverless NEG. | `api.marketsniperai.com` | (GCP) | Day 55 |
| **OS.Infra.Hosting** | Firebase Hosting | INFRA | Static Assets + Rewrite Layer. | `*.web.app` | `firebase.json` | Day 55 |
| **OS.Infra.LayoutPolice** | Layout Police | OPS | Runtime Layout Guard. | (Internal) | `lib/guards/layout_police.dart` | D43 |

## 2. Operations Layer (The Body)

| Module ID | Name | Type | Description | Key Port (Endpoint) | Primary File | Seal Ref |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **OS.Ops.Pipeline** | Pipeline Controller | OPS | Orchestrates data generation pipelines. | `POST /lab/run_pipeline` | `backend/pipeline_controller.py` | Day 06 |
| **OS.Ops.Misfire** | Misfire Monitor | OPS | Detects missed schedules and triggers auto-heal. | `GET /misfire` | `backend/os_ops/misfire_monitor.py` | D08, D14 |
| **OS.Ops.AutoFix** | AutoFix Control Plane | OPS | Recommends and executes recovery actions. | `GET /autofix` | `backend/os_ops/autofix_control_plane.py` | D15, D16 |
| **OS.Ops.Housekeeper** | Housekeeper Engine | OPS | Hygiene Engine (Wired/Manual). | `GET /housekeeper` | `backend/os_ops/housekeeper.py` | D17, D56 |
| **OS.Ops.Iron** | Iron OS | OPS | State Management, Replay, and History Engine. | `GET /lab/os/iron/status` | `backend/os_ops/iron_os.py` | D41 |
| **OS.Ops.Replay** | Replay Archive | OPS | Time Machine for Operational States. | `GET /lab/replay/archive/tail` | `backend/os_ops/replay_archive.py` | D41 |
| **OS.Ops.Rollback** | Rollback Ledger | OPS | Founder Intent Ledger for State Rollbacks. | `POST /lab/os/rollback` | `backend/os_ops/rollback_ledger.py` | D41 |
| **OS.Ops.WarRoom** | War Room | OPS | Unified command center (V2 Refactor). | `GET /lab/war_room` | `backend/os_ops/war_room.py` | D18, D53 |
| **OS.Ops.ImmuneSystem** | Immune System | OPS | Active defense against poisoned inputs. | `GET /immune/status` | `backend/os_ops/immune_system.py` | D32 |
| **OS.Ops.BlackBox** | Black Box | OPS | Forensic Indestructibility & Truth Recorder. | `GET /blackbox/status` | `backend/os_ops/black_box.py` | D34 |
| **OS.Ops.ShadowRepair** | Shadow Repair | OPS | Proposes Patches and Executes Runtime Surgery. | `POST /lab/shadow_repair/propose` | `backend/os_ops/shadow_repair.py` | D28 |
| **OS.Ops.TuningGate** | Tuning Gate | OPS | Governance for Runtime Tuning (2-Vote). | `POST /lab/tuning/apply` | `backend/os_ops/tuning_gate.py` | D33 |
| **OS.Ops.ReliabilityLedgerGlobal** | Reliability Ledger | OPS | Append-only record of projections. | (Internal) | `backend/os_ops/reliability_ledger_global.py` | D48 |
| **OS.Ops.ReliabilityReconciler** | Reliability Reconciler | OPS | Closes the loop with realized outcomes. | (Internal) | `backend/os_ops/reliability_reconciler.py` | D48 |
| **OS.Ops.KnowledgeIndex** | Knowledge Index | OPS | SSOT of all OS modules. | (Artifact) | `backend/os_ops/generate_os_knowledge_index.py` | D49 |
| **OS.Ops.CalibrationReport** | Calibration Report | OPS | Generates accuracy artifacts. | (Artifact) | `backend/os_ops/calibration_report_engine.py` | D48 |
| **OS.Ops.StateSnapshot** | State Snapshot | OPS | Real-time system health for Elite (V3). | `GET /os/state_snapshot` | `backend/os_ops/state_snapshot_engine.py` | D49, D56 |
| **OS.Ops.EventRouter** | Event Router | OPS | Central System Event Bus. | `GET /events/latest` | `backend/os_ops/event_router.py` | D48 |
| **OS.Ops.Voice** | Voice MVP Stub | OPS | Governance stub for future Voice Engine. | `GET /voice_state` | `backend/voice_mvp_engine.py` | D36 |

## 3. Intelligence Layer (The Mind)

| Module ID | Name | Type | Description | Key Port (Endpoint) | Primary File | Seal Ref |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **OS.Intel.Foundation** | AGMS Foundation | INTEL | Memory, Truth Mirror, and Base Truth. | `GET /agms/foundation` | `backend/os_intel/agms_foundation.py` | D20 |
| **OS.Intel.Intel** | AGMS Intelligence | INTEL | Pattern recognition and coherence analysis. | `GET /agms/intelligence` | `backend/os_intel/agms_intelligence.py` | D21 |
| **OS.Intel.Dojo** | The Dojo | INTEL | Offline Simulation & Deep Dreaming. | `POST /lab/dojo/run` | `backend/os_intel/dojo_simulator.py` | D33 |
| **OS.Intel.ShadowRec** | AGMS Any-Shadow | INTEL | Maps patterns to Shadow Playbooks. | `GET /agms/shadow/suggestions` | `backend/os_intel/agms_shadow_recommender.py` | D22 |
| **OS.Intel.Handoff** | Autopilot Handoff | INTEL | Secure bridge from Thinker to Actor. | `GET /agms/handoff` | `backend/os_intel/agms_autopilot_handoff.py` | D23 |
| **OS.Intel.Thresholds** | Dynamic Thresholds | INTEL | Self-tuning sensitivity based on market state. | `GET /agms/thresholds` | `backend/os_intel/agms_dynamic_thresholds.py` | D24 |
| **OS.Intel.Bands** | Confidence Bands | INTEL | Standardizes confidence levels. | (Artifact) | `backend/os_intel/agms_stability_bands.py` | D25 |
| **OS.Intel.Options** | Options Intelligence | INTEL | Descriptive IV/Skew/Move context (N/A Safe). | `GET /options_context` | `backend/options_engine.py` | D36 |
| **OS.Intel.Macro** | Macro Layer | INTEL | Rates/USD/Oil context + degradation. | `GET /macro_context` | `backend/macro_engine.py` | D36 |
| **OS.Intel.Evidence** | Evidence Engine | INTEL | Regime matching + Sample Size guard. | `GET /evidence_summary` | `backend/evidence_engine.py` | D36 |
| **OS.Intel.Projection** | Projection Orchestrator | INTEL | Central mixing engine (Fusion). | `GET /projection/report` | `backend/os_intel/projection_orchestrator.py` | D47 |
| **OS.Intel.News** | News Engine | INTEL | Unified News Truth (Source Ladder). | `GET /news_digest` | `backend/news_engine.py` | D47 |
| **OS.Intel.Calendar** | Economic Calendar | INTEL | High-Impact Event Schedule. | `GET /economic_calendar` | `backend/os_intel/economic_calendar_engine.py` | D45 |
| **OS.Intel.Attribution** | Attribution Engine | INTEL | "Show Work" Logic for Projections. | (Internal) | `backend/os_intel/projection_orchestrator.py` | D48 |
| **OS.Intel.IntradaySeries** | Intraday Series | INTEL | Deterministic 5m candle generator. | (Internal) | `backend/os_intel/intraday_series_source.py` | D47 |
| **OS.Intel.ContextTagger** | Context Tagger | INTEL | Semantic tagging for inputs. | (Internal) | `backend/os_intel/context_tagger.py` | (Code) |
| **OS.Intel.RitualRouter** | Ritual API Router | INTEL | Router for ritual artifacts. | `GET /elite/ritual/*` | `backend/os_intel/elite_ritual_router.py` | D49 |
| **OS.Intel.ChatCore** | Elite Chat Core | INTEL | Hybrid Chat + Tool Router. | `POST /elite/chat` | `backend/os_intel/elite_chat_router.py` | D49 |
| **OS.Intel.UserMemory** | User Memory | INTEL | Longitudinal user reflection. | (Internal) | `backend/os_intel/elite_user_memory_engine.py` | D49 |
| **OS.Intel.LLMBoundary** | LLM Boundary | INTEL | Safe LLM wrapper with cost/PII guards. | (Internal) | `backend/os_llm/elite_llm_boundary.py` | D48 |

## 4. Data Layer

| Module ID | Name | Type | Description | Key Port (Endpoint) | Primary File | Seal Ref |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **OS.Data.DataMux** | Provider DataMux | DATA | Multi-Provider Failover Layer. | (Internal) | `backend/os_data/datamux.py` | D48 |
| **OS.OnDemand.Cache** | On-Demand Cache | DATA | Universe-agnostic analysis cache. | (Internal) | `backend/os_ops/hf_cache_server.py` | D47 |
| **OS.OnDemand.Global** | Global Cache Server | DATA | Shared dossier deduplication (Public). | (Internal) | `backend/os_ops/global_cache_server.py` | D47 |
| **OS.OnDemand.Recent** | Recent Dossier Store | DATA | Local offline snapshot persistence. | (Internal) | `lib/logic/recent_dossier_store.dart` | D47 |
| **OS.Data.Provider.AlphaVantage** | Alpha Vantage Driver | DATA | Batch-Only Provider Integration. | (Artifact) | `backend/providers/alpha_vantage_client.py` | D62 |

## 5. UI & Surfaces Layer

| Module ID | Name | Type | Description | Key File | Seal Ref |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **OS.Biz.Dashboard** | Dashboard Features | FEATURE | Main user interface data payload. | `backend/schemas/dashboard_schema.py` | D05, D37 |
| **OS.Biz.Context** | Context | FEATURE | Narrative context and market status. | `backend/schemas/context_schema.py` | D36 |
| **UI.Layout.DashboardComposer** | Dashboard Composer | UI | Dashboard Widget Orchestrator. | `lib/screens/dashboard/dashboard_composer.dart` | Canon |
| **UI.Component.DashboardCard** | Dashboard Card | UI | Canonical Card Wrapper. | `lib/ui/components/dashboard_card.dart` | Canon |
| **UI.WarRoom.Shell** | War Room Shell | UI | Institutional Command Center Shell. | `lib/screens/war_room_screen.dart` | D18, D53 |
| **OS.UI.UniverseScreen** | Universe Screen | UI | Core Universe Management. | `lib/screens/universe_screen_v2.dart` | D39 |
| **OS.UI.OnDemandPanel** | On-Demand Panel | UI | Ticker search and analysis surface. | `lib/screens/on_demand_panel.dart` | D44 |
| **OS.UI.WatchlistScreen** | Watchlist Screen | UI | Persistent watchlist management. | `lib/screens/watchlist_screen.dart` | D44 |
| **OS.UI.NewsTab** | News Tab | UI | Flip-card daily digest surface. | `lib/screens/news_screen.dart` | D45 |
| **OS.UI.CalendarTab** | Economic Calendar | UI | Impact-rated event schedule. | `lib/screens/calendar_screen.dart` | D45 |
| **OS.UI.PremiumMatrix** | Premium Matrix | UI | Feature comparison and upgrade. | `lib/screens/premium_feature_matrix.dart` | D45 |
| **OS.UI.ShareSheet** | Share Sheet | UI | Watermarked image export. | `lib/screens/share_sheet.dart` | D45 |
| **OS.UI.CommandCenter** | Command Center | UI | Elite-only mystery surface. | `lib/screens/command_center_screen.dart` | D45, D61 |
| **OS.UI.CoherenceQuartet** | Coherence Quartet | UI | Premium Anchor (4-Quadrant). | `lib/widgets/command_center/coherence_quartet_card.dart` | D61 |
| **OS.UI.RegimeSentinel** | Regime Sentinel | UI | Index Detail Widget (Skeleton). | `lib/widgets/dashboard/regime_sentinel_widget.dart` | D46 |
| **UI.Synthesis.Global** | Global Pulse | UI | Risk State/Driver Synthesis. | `_buildGlobalPulseSection` | D40 |
| **OS.UI.SectorSentinel** | Sector Sentinel | UI | Real-Time Sector Strip. | `_buildSectorSentinelSection` | D40 |
| **OS.UI.TimeTraveller** | Time Traveller | UI | Interactive H/L/C Chart. | `lib/widgets/time_traveller_chart.dart` | D47 |
| **OS.UI.ReliabilityMeter** | Reliability Meter | UI | Real-time Accuracy/Uptime visuals. | `lib/widgets/reliability_meter.dart` | D47 |
| **OS.UI.TacticalPlaybook** | Tactical Playbook | UI | AI Strategy & Setup visualization. | `lib/widgets/tactical_playbook_card.dart` | D47 |
| **OS.UI.IntelCards** | Intel Cards | UI | Carousel of synthesis briefings. | `lib/widgets/intel_cards_carousel.dart` | D47 |
| **OS.UI.MicroBriefing** | Micro Briefing | UI | Briefing content widget. | (Widget) | D47 |
| **OS.Elite.ShellV2** | Elite Shell V2 | UI | Glass Ritual Panel Overlay (70%). | `lib/widgets/elite_interaction_sheet.dart` | D49 |
| **OS.Elite.Overlay** | Elite Overlay | UI | 70/30 Context Shell (Base). | `lib/widgets/elite_interaction_sheet.dart` | D43 |
| **OS.Elite.RitualGrid** | Ritual Grid | UI | 2x3 Ritual Selection Grid. | `lib/widgets/elite/ritual_grid.dart` | D49 |
| **OS.Elite.BadgeController** | Badge Controller | UI | Notification Badge Logic. | `lib/controllers/elite_badge_controller.dart` | D49 |
 
## 6. Logic & Governance Layer
 
| Module ID | Name | Type | Description | Key File | Seal Ref |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **OS.Logic.WatchlistStore** | Watchlist Store | LOGIC | Local persistence for tickers. | `lib/logic/watchlist_store.dart` | D44 |
| **OS.Logic.TabState** | Tab State Store | LOGIC | Bottom nav persistence. | `lib/logic/tab_state_store.dart` | D45 |
| **OS.Logic.Ritual** | Ritual Scheduler | LOGIC | Local notification triggers. | `lib/logic/ritual_scheduler.dart` | D43 |
| **OS.Logic.RitualPolicy** | Ritual Policy Engine | LOGIC | Windows + Countdown Logic. | `backend/os_ops/elite_ritual_policy.py` | D49 |
| **OS.Logic.FreeWindow** | Free Window Ledger | LOGIC | Monday Free Window Tracking. | `backend/os_intel/elite_free_window_ledger.py` | D49 |
| **OS.Domain.Universe** | Universe Domain | LOGIC | `Core20` Definitions. | `lib/domain/core20_universe.dart` | Canon |
| **OS.Contract.WarRoom** | War Room Contract | CONTRACT | SSOT for Required Keys (Hydration). | `backend/contracts/war_room_contract.py` | D56 |
| **OS.OnDemand.Ledger** | Computation Ledger | LOGIC | Daily Cost Policy Enforcer. | `backend/os_ops/computation_ledger.py` | D44 |
| **OS.OnDemand.Resolver** | Tier Resolver | LOGIC | Founder/Elite/Plus/Free Resolution. | `lib/logic/on_demand_tier_resolver.dart` | D47 |
| **OS.Security.EliteGate** | Elite Gate | LOGIC | Fail-closed cost/write protection. | `backend/security/elite_gate.py` | D58 |

## 7. Tooling Layer

| Module ID | Name | Type | Description | Key Command | Seal Ref |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Tool.Verifier.Discipline** | Discipline Verifier | TOOL | Enforces detailed canonical rules. | `python backend/os_ops/verify_project_discipline.py` | Canon |
| **Tool.Verifier.Schema** | Schema Authority | TOOL | Enforces strict JSON contracts. | `python backend/verify_schema_authority_v1.py` | D48 |
| **Tool.Verifier.Dashboard** | Layout Verifier | TOOL | Enforces dashboard specific layout rules. | `verify_dashboard_layout_discipline.py` | Canon |

---

## Canon Drift Report — D63

**Timestamp:** 2026-02-12
**Scope:** Global Reconstruction Scan (Seals D00-D63)

### Summary
- **Total Modules Discovered:** ~85
- **Status:** **NOMINAL** (Reconstructed)

### Historical Gaps Filled (D46-D63)
1.  **Regime Sentinel:** Identified D46 Skeleton seal. Added to UI Layer.
2.  **Attribution:** Identified D48Logic seal. Added to Intel Layer.
3.  **Global Pulse / Sector Sentinel:** Identified D40 seals. Added to UI Layer.
4.  **Coherence Quartet:** Identified D61 seal. Added to UI Layer.
5.  **Alpha Vantage:** Identified D62 seal. Added to Data Layer.
6.  **Elite Gate:** Identified D58 seal. Added to Logic/Security Layer.

### Anomalies
- Some "Modules" like `OS.UI.MicroBriefing` might be widgets rather than full modules, but are tracked as distinct functionality units in seals.
- `Tool.Verifier.Schema` is sometimes referred to as `OS.Intel.SchemaAuthority` in seals. Standardized on `Tool.` prefix for CLI tools, but kept `OS.Intel.Projection` context.

**Verification:**
This document now represents the **Sole Source of Truth** for System Inventory, deriving purely from the Seal history.
