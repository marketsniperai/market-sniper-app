# SEAL: D42.AutoStagePatch — Auto-Stage Canon Outputs Patch

## Status: SEALED
## Date: 2026-01-17
## Proof: outputs/proofs/day_42/day_42_auto_stage_patch_proof.json

## Description
Patched the Auto-Stage protocol to resolve the ephemeral contradiction. Canonical proofs are now strictly separated from execution runtime logs.

## Changes
- **Directory**: Created `outputs/proofs/` for permanent proof artifacts.
- **Protocol**: `outputs/runtime/` is now strictly ephemeral (never staged).
- **Tooling**: `auto_stage_canon_outputs.py` updated to use `git status --porcelain -uall` and stage `outputs/proofs/`.
- **Enforcement**: `verify_project_discipline.py` updated to check `outputs/proofs/` for untracked files.
- **Constitution**: Updated to reflect the separation (Runtime=Ephemeral, Proofs=Mandatory).

## Verification
- Dummy proof in `outputs/proofs/` was successfully staged by the tool.
- Dummy file in `outputs/runtime/` was correctly ignored.
- Verifier confirms system discipline.

## Next Steps
Use `outputs/proofs/` for all future proof artifacts.
