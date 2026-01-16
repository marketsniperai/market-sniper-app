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
| **OS.Ops.Pipeline** | Pipeline Controller | OPS | Orchestrates data generation pipelines. | `POST /lab/run_pipeline` | `backend/pipeline_controller.py` |
| **OS.Ops.Misfire** | Misfire Monitor | OPS | Detects missed schedules and triggers auto-heal. | `GET /misfire`, `POST /lab/misfire_autoheal` | `backend/os_ops/misfire_monitor.py` |
| **OS.Ops.AutoFix** | AutoFix Control Plane | OPS | Recommends and executes recovery actions. | `GET /autofix`, `POST /lab/autofix/execute` | `backend/os_ops/autofix_control_plane.py` |
| **OS.Ops.Housekeeper** | Housekeeper | OPS | Cleans operational trash and drift. | `GET /housekeeper`, `POST /lab/housekeeper/run` | `backend/os_ops/housekeeper.py` |
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
