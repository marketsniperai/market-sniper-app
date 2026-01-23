# OS MODULES INVENTORY (Canon)

**Authority:** IMMUTABLE
**Version:** 3.0 (Day 45 - Feature Phase)

> **Days vs Modules**: "Days" represent the history of seals (time). "Modules" represent the operable units of the system (space).

## System Graph

### Operations Chain (The Body)
`Misfire Monitor` → `AutoFix Control Plane` → `Autopilot Policy Engine` → `Execution`
`Housekeeper` → `War Room` (Observer) → `Iron OS` (State)

### AGMS Intelligence Chain (The Mind)
`AGMS Foundation` → `AGMS Intelligence` → `Shadow Recommender` → `Autopilot Handoff`
`Dynamic Thresholds` ↔ `Confidence Bands` → `Evidence` → `Options` → `Macro`

### Elite Arc (The Voice)
`Elite Context` → `Explain Router` → `Interactive Shell`

---

## Module Inventory

| Module ID | Name | Type | Description | Key Port (Endpoint) | Primary File |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **OS.Infra.API** | API Server | CORE | Entry point for all system interactions. | `/*` | `backend/api_server.py` |
| **OS.Infra.Gates** | Core Gates | CORE | Enforces system safety and data freshness. | (Internal Function) | `backend/gates/core_gates.py` |
| **Tool.Verifier.Discipline** | Discipline Verifier | TOOL | Enforces detailed canonical rules (Colors/Layout). | `python backend/os_ops/verify_project_discipline.py` | `backend/os_ops/verify_project_discipline.py` |
| **Tool.Verifier.DashboardLayout** | Layout Verifier | TOOL | Enforces dashboard specific layout rules. | (Called by Discipline) | `backend/os_ops/verify_dashboard_layout_discipline.py` |
| **OS.Ops.Pipeline** | Pipeline Controller | OPS | Orchestrates data generation pipelines. | `POST /lab/run_pipeline` | `backend/pipeline_controller.py` |
| **OS.Ops.Misfire** | Misfire Monitor | OPS | Detects missed schedules and triggers auto-heal. | `GET /misfire`, `POST /lab/misfire_autoheal` | `backend/os_ops/misfire_monitor.py` |
| **OS.Ops.AutoFix** | AutoFix Control Plane | OPS | Recommends and executes recovery actions. | `GET /autofix`, `POST /lab/autofix/execute` | `backend/os_ops/autofix_control_plane.py` |
| **OS.Ops.Housekeeper** | Housekeeper | OPS | Cleans operational trash and drift. | `GET /housekeeper`, `POST /lab/housekeeper/run` | `backend/os_ops/housekeeper.py` |
| **OS.Ops.Iron** | Iron OS | OPS | State Management, Replay, and History Engine. | `GET /lab/os/iron/status` | `backend/os_ops/iron_os.py` |
| **OS.Ops.Replay** | Replay Archive | OPS | Time Machine for Operational States. | `GET /lab/replay/archive/tail` | `backend/os_ops/replay_archive.py` |
| **OS.Ops.Rollback** | Rollback Ledger | OPS | Founder Intent Ledger for State Rollbacks. | `POST /lab/os/rollback` | `backend/os_ops/rollback_ledger.py` |
| **OS.Ops.WarRoom** | War Room | OPS | Unified command center for visibility. | `GET /lab/war_room` | `backend/os_ops/war_room.py` |
| **OS.Ops.ImmuneSystem** | Immune System | OPS | Active defense against poisoned inputs. | `GET /immune/status` | `backend/os_ops/immune_system.py` |
| **OS.Ops.BlackBox** | Black Box | OPS | Forensic Indestructibility & Truth Recorder. | `GET /blackbox/status` | `backend/os_ops/black_box.py` |
| **OS.Ops.ShadowRepair** | Shadow Repair | OPS | Proposes Patches and Executes Runtime Surgery. | `POST /lab/shadow_repair/propose` | `backend/os_ops/shadow_repair.py` |
| **OS.Ops.TuningGate** | Tuning Gate | OPS | Governance for Runtime Tuning (2-Vote). | `POST /lab/tuning/apply` | `backend/os_ops/tuning_gate.py` |
| **OS.Intel.Foundation** | AGMS Foundation | INTELLIGENCE | Memory, Truth Mirror, and Base Truth. | `GET /agms/foundation` | `backend/os_intel/agms_foundation.py` |
| **OS.Intel.Intel** | AGMS Intelligence | INTELLIGENCE | Pattern recognition and coherence analysis. | `GET /agms/intelligence` | `backend/os_intel/agms_intelligence.py` |
| **OS.Intel.Dojo** | The Dojo | INTELLIGENCE | Offline Simulation & Deep Dreaming. | `POST /lab/dojo/run` | `backend/os_intel/dojo_simulator.py` |
| **OS.Intel.ShadowRec** | AGMS Any-Shadow | INTELLIGENCE | Maps patterns to Shadow Playbooks. | `GET /agms/shadow/suggestions` | `backend/os_intel/agms_shadow_recommender.py` |
| **OS.Intel.Handoff** | Autopilot Handoff | INTELLIGENCE | Secure bridge from Thinker (AGMS) to Actor (AutoFix). | `GET /agms/handoff` | `backend/os_intel/agms_autopilot_handoff.py` |
| **OS.Intel.Thresholds** | Dynamic Thresholds | INTELLIGENCE | Self-tuning sensitivity based on market state. | `GET /agms/thresholds` | `backend/os_intel/agms_dynamic_thresholds.py` |
| **OS.Intel.Bands** | Confidence Bands | INTELLIGENCE | Standardizes confidence levels (Green/Yellow/Orange). | (Artifact Output) | `backend/os_intel/agms_stability_bands.py` |
| **OS.Intel.Options** | Options Intelligence | INTELLIGENCE | Descriptive IV/Skew/Move context (N/A Safe). | `GET /options_context` | `backend/options_engine.py` |
| **OS.Intel.Macro** | Macro Layer | INTELLIGENCE | Rates/USD/Oil context + degradation. | `GET /macro_context` | `backend/macro_engine.py` |
| **OS.Intel.Evidence** | Evidence Engine | INTELLIGENCE | Regime matching + Sample Size guard. | `GET /evidence_summary` | `backend/evidence_engine.py` |
| **OS.Ops.Voice** | Voice MVP Stub | OPS | Governance stub for future Voice Engine. | `GET /voice_state` | `backend/voice_mvp_engine.py` |
| **OS.Elite.Reader** | Elite OS Reader | OPS | Elite Context Aggregator. | (Internal) | `backend/os_ops/elite_os_reader.py` |
| **OS.Elite.Recall** | Elite Recall | INTELLIGENCE | Contextual memory retrieval. | (Internal) | `backend/os_ops/elite_agms_recall_reader.py` |
| **OS.Elite.Safety** | Elite Safety | OPS | Institutional tone & claim enforcement. | (Internal) | `backend/os_ops/elite_context_safety_validator.py` |
| **OS.OnDemand.Cache** | On-Demand Cache | DATA | Universe-agnostic analysis cache. | (Internal) | `backend/os_ops/on_demand_cache.py` |
| **OS.Biz.Dashboard** | Dashboard | FEATURE | Main user interface data payload. | `GET /dashboard` | `backend/schemas/dashboard_schema.py` |
| **OS.Biz.Context** | Context | FEATURE | Narrative context and market status. | `GET /context` | `backend/schemas/context_schema.py` |
| **OS.Biz.Efficacy** | Efficacy Engine | FEATURE | Tracks prediction accuracy. | `GET /efficacy` | `backend/schemas/efficacy_schema.py` |

## UI Module Inventory

| Module ID | Name | Type | Description | Key File | D-Ref |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **UI.Theme.Typography** | Typography | UI | Canonical TextStyles (SSOT). | `lib/theme/app_typography.dart` | Canon |
| **UI.Layout.DashboardSpacingTokens** | Spacing Tokens | UI | Canonical Spacing Tokens. | `lib/ui/tokens/dashboard_spacing.dart` | Canon |
| **UI.Layout.DashboardComposer** | Dashboard Composer | UI | Dashboard Widget Orchestrator. | `lib/screens/dashboard/dashboard_composer.dart` | Canon |
| **UI.Component.DashboardCard** | Dashboard Card | UI | Canonical Card Wrapper. | `lib/ui/components/dashboard_card.dart` | Canon |
| **UI.WarRoom.Shell** | War Room Shell | UI | Institutional Command Center Shell. | `lib/screens/war_room_screen.dart` | D18 |
| **UI.WarRoom.Wiring** | War Room Wiring | UI | War Room Data Wiring & Models. | `lib/repositories/war_room_repository.dart` | D38 |
| **OS.UI.UniverseScreen** | Universe Screen | UI | Core Universe Management. | `lib/screens/universe_screen_v2.dart` | D39 |
| **OS.UI.OnDemandPanel** | On-Demand Panel | UI | Ticker search and analysis surface. | `lib/screens/on_demand_panel.dart` | D44 |
| **OS.UI.WatchlistScreen** | Watchlist Screen | UI | Persistent watchlist management. | `lib/screens/watchlist_screen.dart` | D44 |
| **OS.UI.NewsTab** | News Tab | UI | Flip-card daily digest surface. | `lib/screens/news_screen.dart` | D45 |
| **OS.UI.CalendarTab** | Economic Calendar | UI | Impact-rated event schedule. | `lib/screens/calendar_screen.dart` | D45 |
| **OS.UI.PremiumMatrix** | Premium Matrix | UI | Feature comparison and upgrade. | `lib/screens/premium_feature_matrix.dart` | D45 |
| **OS.UI.ShareSheet** | Share Sheet | UI | Watermarked image export. | `lib/screens/share_sheet.dart` | D45 |
| **OS.UI.CommandCenter** | Command Center | UI | Elite-only mystery surface. | `lib/screens/command_center_screen.dart` | D45 |
| **OS.Elite.Overlay** | Elite Overlay | UI | 70/30 Context Shell. | `lib/widgets/elite_interaction_sheet.dart` | D43 |
| **OS.Elite.Router** | Explain Router | UI | Maps queries to specialized modules. | `lib/logic/elite_explain_router.dart` | D43 |
| **OS.Infra.LayoutPolice** | Layout Police | OPS | Runtime Layout Guard. | `lib/guards/layout_police.dart` | D43 |

## Logic & Governance Modules

| Module ID | Name | Type | Description | Key File | D-Ref |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **OS.Logic.WatchlistStore** | Watchlist Store | Logic | Local persistence for tickers. | `lib/logic/watchlist_store.dart` | D44 |
| **OS.Logic.TabState** | Tab State Store | Logic | Bottom nav persistence. | `lib/logic/tab_state_store.dart` | D45 |
| **OS.Logic.Ritual** | Ritual Scheduler | Logic | Local notification triggers. | `lib/logic/ritual_scheduler.dart` | D43 |
| **OS.Domain.Universe** | Universe Domain | Logic | `Core20` Definitions. | `lib/domain/core20_universe.dart` | Canon |

## Legacy Content Modules (Reconciled)
*   **Briefing**: `GET /briefing` (Active)
*   **Aftermarket**: `GET /aftermarket` (Active)
*   **Sunday Setup**: `GET /sunday_setup` (Active)
*   **Options Report**: `GET /options_report` (Legacy PDF/Text - superseded by `options_context` for logic, but endpoint remains active).
