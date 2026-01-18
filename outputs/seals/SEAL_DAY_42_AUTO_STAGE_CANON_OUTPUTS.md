# SEAL: D42.AutoStage — Auto-Stage Canon Outputs

## Status: SEALED
## Date: 2026-01-17
## Proof: outputs/runtime/day_42/day_42_auto_stage_canon_proof.json

## Description
Implemented and enforced the "Auto-Stage Canon Outputs" protocol. This mechanism automatically stages canonical artifacts (Seals, Proofs, Calendar, State) after every task, preventing the "untracked seal" blocking issue and ensuring Git hygiene by strictly enforcing an Allowlist/Denylist.

## Implementation
- **Tool**: `tool/auto_stage_canon_outputs.py`
    - **Allowlist**: `outputs/seals/*.md`, `outputs/runtime/*.json`, `OMSR_WAR_CALENDAR...`, `PROJECT_STATE.md`, `OS_MODULES.md`, `os_registry.json`.
    - **Denylist**: Build artifacts, keys, secrets, logs.
- **Enforcement**: Updated `backend/os_ops/verify_project_discipline.py` to fail if any seal or proof remains untracked.
- **Governance**: Updated `ANTIGRAVITY_CONSTITUTION.md` to mandate this step in the Finish Protocol.

## Verification
- **Test Run**: Created dummy seal/proof. Verifier initially failed (CORRECT). Auto-stager ran. Verifier passed (CORRECT).
- **Artifacts**: New tool and updated verifier are staged.

## Next Steps
All future tasks MUST run `python tool/auto_stage_canon_outputs.py` before sealing.
