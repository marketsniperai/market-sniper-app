# D56.HK.0 INTELLIGENCE REPORT: HOUSEKEEPER SUBSYSTEM

**Date:** 2026-02-05
**Investigator:** Antigravity
**Status:** READ-ONLY AUDIT (NO CHANGES)

## 1. Executive Summary
The **Housekeeper** module (`backend/os_ops/housekeeper.py`) exists as a defined, deterministic engine for file hygiene and maintenance. However, it is currently **completely disconnected** from the runtime environment. The API endpoints claimed in `SEAL_DAY_42_03` are **missing** from `api_server.py`, and it is not triggered by Misfire Monitor or AutoFix Control Plane. It is effective "Dead Code" awaiting activation.

## 2. Definition & Intent
- **Role**: "Deterministic Execution Engine" for System Hygiene.
- **Design Pattern**: Plan-Execute-Verify.
    - **Plan**: `outputs/os/os_housekeeper_plan.json` (Strict Schema).
    - **Execute**: `Housekeeper.run_from_plan()`.
    - **Verify**: Writes results to `os_findings.json` and `os_before_after_diff.json`.
- **Safety Philosophy**: "No Inference". If the plan is missing or invalid, it does nothing (NO-OP).

## 3. Code Structure & Inventory
- **Core Logic**: `backend/os_ops/housekeeper.py` (308 lines).
    - Classes: `Housekeeper`, `HousekeeperAction`, `HousekeeperPlan`, `HousekeeperRunResult`.
- **Plan Artifact**: `outputs/os/os_housekeeper_plan.json` (Currently contains a `TEST_PLAN_02` with `DESTROY_WORLD` action).
- **Runtime Artifacts**:
    - `outputs/os/os_findings.json`
    - `outputs/os/os_before_after_diff.json`
    - `outputs/backups/housekeeper/*.bak` (Backup storage).

## 4. Wiring & Dependencies (CRITICAL FINDINGS)
- **API Wiring**: **MISSING**.
    - Seal `SEAL_DAY_42_03` claims `POST /lab/os/self_heal/housekeeper/run` exists.
    - **Reality**: `grep` confirms NO reference to `housekeeper` in `backend/api_server.py`.
- **Misfire Monitor**: **DISCONNECTED**.
    - `backend/os_ops/misfire_monitor.py` verifies artifacts but triggers `market-sniper-pipeline` (Cloud Run Job), NOT Housekeeper.
- **AutoFix**: **DISCONNECTED**.
    - `autofix_control_plane.py` executes Playbooks which trigger Pipeline jobs, but has no logic to invocation Housekeeper.

## 5. Governance & Safety
The module has strong *internal* safety but zero *external* access.
- **Allowlist (Hardcoded)**:
    - `CLEAN_ORPHANS`: Implemented. Checks target is within `OUTPUTS_DIR`.
    - `NORMALIZE_FLAGS`: Mock implication.
    - **Blocked**: `DESTROY_WORLD` (from current test plan) would be correctly SKIPPED.
- **Invariants**:
    - **Reversibility**: Action must be `reversible: true`.
    - **Backups**: `_create_backup()` runs before any deletion.
    - **Scope**: Targets must be inside `OUTPUTS_DIR` (checked via `startswith`).

## 6. Known Issues & Debt
- **Documentation Drift**: Canon (`OS_MODULES.md`) and Seals (`SEAL_DAY_42_03`) describe endpoints that do not exist in code.
- **Unreachable**: Functionality cannot be tested or used without code changes (wiring).

## 7. Readiness Assessment
- **Logic Readiness**: **HIGH**. The `housekeeper.py` code handles plans, allowlists, backups, and proofs correctly.
- **Integration Readiness**: **LOW**. Needs API wiring and/or integration into `autofix_control_plane.py` as a tool.
- **Plan Generation**: **MISSING**. There is no "Housekeeper Planner" module. The plan must be generated externally (e.g., by AGMS or Founder).

## 8. Recommendations for D56.HK.1
1.  **Wire API**: Restore/Add `POST /lab/housekeeper/run` to `api_server.py`.
2.  **Update Allowlist**: Ensure `CLEAN_ORPHANS` covers intended targets (e.g. `outputs/runtime/` debris).
3.  **Plan Source**: Define who creates `os_housekeeper_plan.json`. (Likely manual for now, or a new "Planner" job).

**End of Report.**
