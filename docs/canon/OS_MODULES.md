# OS MODULES INVENTORY (Canon)

**Authority:** IMMUTABLE
**Version:** 2.1 (Day 31)

> **Days vs Modules**: "Days" represent the history of seals (time). "Modules" represent the operable units of the system (space).

## System Graph

### Operations Chain (The Body)
`Misfire Monitor` → `AutoFix Control Plane` → `Autopilot Policy Engine` → `Execution`
`Housekeeper` → `War Room` (Observer)

### AGMS Intelligence Chain (The Mind)
`AGMS Foundation` → `AGMS Intelligence` → `Shadow Recommender` → `Autopilot Handoff`
`Dynamic Thresholds` ↔ `Confidence Bands`

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
| **UI.Theme.Typography** | Typography | UI | Canonical TextStyles (SSOT). | (Artifact Output) | `lib/theme/app_typography.dart` |
| **UI.Layout.DashboardSpacingTokens** | Spacing Tokens | UI | Canonical Spacing Tokens. | (Artifact Output) | `lib/ui/tokens/dashboard_spacing.dart` |
| **UI.Layout.DashboardComposer** | Dashboard Composer | UI | Dashboard Widget Orchestrator. | (Internal Function) | `lib/screens/dashboard/dashboard_composer.dart` |
| **UI.Component.DashboardCard** | Dashboard Card | UI | Canonical Card Wrapper. | (Internal Function) | `lib/ui/components/dashboard_card.dart` |
| **UI.WarRoom.Shell** | War Room Shell | UI | Institutional Command Center Shell. | (Internal Function) | `lib/screens/war_room_screen.dart` |
| **UI.WarRoom.Wiring** | War Room Wiring | UI | War Room Data Wiring & Models. | (Internal Function) | `lib/repositories/war_room_repository.dart` |
| **OS.Domain.Universe** | Domain | `Core20Universe` | Canon | `core20_universe.dart` | `UniverseRepository`, `UniverseScreen` |
| **OS.Repo.Universe** | Repository | `UniverseRepository` | Data | `universe_repository.dart` | `UniverseScreen` |
| **OS.UI.UniverseScreen** | UI | `UniverseScreen` | Screen | `universe_screen.dart` | `WatchlistAddModal` |
| **OS.UI.WatchlistAddModal** | UI | `WatchlistAddModal` | Widget | `watchlist_add_modal.dart` | `WatchlistScreen` |
| **OS.UI.OnDemandTab** | UI | `OnDemandPanel` | Panel | `on_demand_panel.dart` | `MainLayout` |
| **OS.Logic.WatchlistStore** | Logic | `WatchlistStore` | Persistence | `watchlist_store.dart` | `WatchlistScreen` |
| **UI.Universe.Extended** | UI | Extended Universe Surface | Universal | `universe_screen.dart` | `D39.02` |
| **UI.Universe.Governance** | UI | Extended Governance Visibility | Universal | `universe_screen.dart` | `D39.03` |
| **UI.Universe.OverlayTruth** | UI | Overlay Truth Metadata Surface | Universal | `universe_screen.dart` | `D39.04` |
| **UI.Universe.OverlaySummaryInjection** | UI | Extended AI Context Summary | Universal | `universe_screen.dart` | `D39.05` |
| **UI.Universe.IntegrityTile** | UI | Universe Integrity Traffic Light | Universal | `universe_screen.dart` | `D39.08` |
| **UI.Universe.PropagationAudit** | UI | Consumer Detection Audit | Universal | `universe_screen.dart` | `D39.06` |
| **UI.Universe.DriftSurface** | UI | Universe Drift Diagnostics | Universal | `universe_screen.dart` | `D39.09` |
| **UI.Universe.SectorSentinel** | UI | Sector Status Placeholder | Universal | `universe_screen.dart` | `D39.11` |
| **UI.Universe.SectorHeatmap** | UI | Sector Dispersion Visualization | Universal | `universe_screen.dart` | `D39.10` |
| **UI.Universe.CoreTape** | UI | Realtime Tape Surface | Universal | `universe_screen.dart` | `D40.01` |
| **UI.Pulse.Core** | UI | Pulse Core State Surface | Universal | `universe_screen.dart` | `D40.02` |
| **UI.Pulse.ConfidenceBands** | UI | Pulse Confidence/Stability | Universal | `universe_screen.dart` | `D40.09` |
| **UI.Pulse.Drift** | UI | Pulse Drift Diagnostics | Universal | `universe_screen.dart` | `D40.10` |
| **UI.Sentinel.RT** | UI | Sector Sentinel Realtime | Universal | `universe_screen.dart` | `D40.03` |
| **UI.Sentinel.Heatmap** | UI | Sentinel Sector Heatmap | Universal | `universe_screen.dart` | `D40.11` |
| **UI.Synthesis.Global** | UI | Global Pulse Synthesis | Universal | `universe_screen.dart` | `D40.05` |
| **UI.RT.PulseTimeline** | UI | Global Pulse Timeline (Last 5) | Universal | `universe_screen.dart` | `D40.12` |
| **UI.RT.FreshnessMonitor** | UI | Real-Time Freshness Monitor | Universal | `universe_screen.dart` | `D40.13` |
| **UI.RT.FreshnessMonitor** | UI | Real-Time Freshness Monitor | Universal | `universe_screen.dart` | `D40.13` |
| **UI.RT.OverlayLiveComposer** | RT | LIVE Overlay Composer | RT | `overlay_live_composer.json` | `D40.04` |
| **UI.RT.Disagreement** | UI | Disagreement Report Surface | Universal | `universe_screen.dart` | `D40.06` |
| **UI.RT.DegradeRules** | UI | Real-Time Degrade Rules | Universal | `universe_screen.dart` | `D40.14` |
| **UI.RT.WhatChanged** | UI | What Changed Micro-Panel | Universal | `universe_screen.dart` | `D40.15` |
| **UI.Elite.ExplainTrigger** | UI | Elite Explain Trigger Bubble | Universal | `universe_screen.dart` | `D40.07` |
| **UI.RT.AutoRiskActions** | UI | Auto-Risk Actions Surface | Universal | `universe_screen.dart` | `D40.08` |
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
| **OS.Biz.Dashboard** | Dashboard | FEATURE | Main user interface data payload. | `GET /dashboard` | `backend/schemas/dashboard_schema.py` |
| **OS.Biz.Context** | Context | FEATURE | Narrative context and market status. | `GET /context` | `backend/schemas/context_schema.py` |
| **OS.Biz.Efficacy** | Efficacy Engine | FEATURE | Tracks prediction accuracy. | `GET /efficacy` | `backend/schemas/efficacy_schema.py` |

## Legacy Content Modules
*   **Briefing**: `GET /briefing`
*   **Aftermarket**: `GET /aftermarket`
*   **Sunday Setup**: `GET /sunday_setup`
*   **Options**: `GET /options_report`

| **OS.Elite.Overlay** | Elite Overlay | UI | 70/30 Context Shell. | (Internal Function) | `lib/widgets/elite_interaction_sheet.dart` |
| **OS.Elite.Router** | Explain Router | UI | Maps queries to specialized modules. | (Internal Function) | `lib/logic/elite_explain_router.dart` |
| **OS.Elite.Safety** | Safety Valve | OPS | Institutional tone enforcement. | (Internal Validator) | `lib/models/elite/context_safety_protocol.dart` |
| **OS.Infra.LayoutPolice** | Layout Police | OPS | Runtime Layout Guard. | (Internal Function) | `lib/guards/layout_police.dart` |
