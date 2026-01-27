# ANTIGRAVITY CONSTITUTION
**Status:** SUPREME LAW  
**Enforcement:** AUTOMATED (`verify_project_discipline.py`)

## 1. Prime Directives
1. **"One Step = One Seal"**: No day ends without a SEAL file.
2. **"No Core OS Change Without Release Checklist"**: Modifying `backend/os_ops/` requires `RELEASE_CHECKLIST.md` evidence.
3. **"AGMS Thinks. Autofix Acts. Policy Decides."**: Respect the Separation of Powers.
4. **"Source is Sacred. Runtime is Regenerable."**: `outputs/runtime/` is ephemeral. Code is eternal.
5. **"Canon is Law"**: If the Code contradicts Canon, the Code is wrong.
6. **"Structural Failure = Rollback First"**:  
   If `flutter analyze`, `flutter run`, or `flutter build` emits **syntax/AST-level errors**
   (e.g. unmatched braces, missing `build()`, “Expected '{'”, “Non-optional parameters can't have a default value”),
   Antigravity MUST:
   - Immediately rollback the affected file(s) to last known good (LKG) via Git
   - Re-apply changes incrementally with verification after each increment  
   **Patch-on-top is PROHIBITED in this state.**

## 2. Mandatory Read Set (The "Truth")
*Before answering complex queries or starting a task, Antigravity MUST verify if these files exist and respect them:*
- `docs/canon/ANTIGRAVITY_CONSTITUTION.md` (This file)
- `docs/canon/PRINCIPIO_OPERATIVO__MADRE_NODRIZA.md` (Operational Core)
- `docs/canon/SYSTEM_ATLAS.md` (Map)
- `docs/canon/OS_MODULES.md` (Module Registry)
- `docs/canon/PENDING_LEDGER.md` (Canon Debt Truth)
- `os_registry.json` (Machine Registry)
- `os_playbooks.yml` (Standard Procedures)
- `os_autopilot_policy.json` (Decision Logic)
- `os_kill_switches.json` (Safety Gates)
- `market_sniper_app/lib/theme/app_colors.dart` (UI Truth)
- `market_sniper_app/lib/theme/app_typography.dart` (UI Fonts)

## 3. Non-Negotiables

### UI & Frontend
- **PROHIBITED:** Hardcoding `Color(0x...)` or `Colors.red/green/etc` in widgets (Exception: `theme/`).
  - *Correction:* Use `AppColors.semanticToken`.
- **PROHIBITED:** Custom TextStyles without `AppTypography`.
  - *Correction:* Use `AppTypography.body(context)`, etc.

### Large File Safety
- **MANDATORY:** Any Dart file **>300 LOC** must follow one of:
  - Block-level edits only (clearly delimited sections), OR
  - Git rollback to LKG + re-apply changes incrementally
- **PROHIBITED:** Multi-feature patching on large files (>300 LOC) **without intermediate compilation checks**.
  - Minimum: compile/verify after each structural change to avoid silent corruption.

### Runtime & Ops
- **PROHIBITED:** Committing files in `outputs/runtime/` to git (Ephemeral).
- **MANDATORY:** Proof artifacts must be stored in `outputs/proofs/` and tracked.
- **MANDATORY:** `PROJECT_STATE.md` must be updated at the end of every Task.
- **MANDATORY:** `outputs/seals/` must be created to close a Task.

### Canon Debt (Pending Law) — Enforcement
- **PENDING LAW:** If a SEAL contains **“Next Steps / Future / Planned / Pending / Upgrade”**, then the same step MUST create or update `docs/canon/PENDING_LEDGER.md` with those items. Otherwise: **DO NOT SEAL**.
- **MANDATORY:** Any such SEAL MUST also create/update the corresponding pending index JSON (e.g. `outputs/proofs/canon/pending_index_v2.json` or latest).
- **MANDATORY:** Pending Closure Hook must include both **Resolved Pending Items** and **New Pending Items** (Effective 2026-01-27).
- **FAILURE CONDITION:** If `PENDING_LEDGER.md` and the pending index JSON are not updated, the SEAL is **INVALID**.

## 4. Finish Protocol
*Every Task concludes with this sequence:*
1. **Update State:** Edit `PROJECT_STATE.md`.
2. **Auto-Stage Canon:** Run `python tool/auto_stage_canon_outputs.py`.
3. **Verify Discipline:** Run `verify_project_discipline.py`.
4. **Seal:** Create `outputs/seals/SEAL_*.md`.
5. **Evidence:** Generate logs in `outputs/proofs/`.

----------------------------------------

ANTIGRAVITY CONSTITUTION 01/26/2025 UPDATE.

Status: SUPREME LAW
Enforcement: AUTOMATED (verify_project_discipline.py)

1. PRIME DIRECTIVES

One Step = One Seal
No task concludes without a verifiable SEAL.

Core OS Changes Require Release Discipline
Modifying backend/os_ops/ requires checklist evidence.

Separation of Powers
AGMS reasons. Autofix executes. Policy arbitrates.

Source is Sacred. Runtime is Regenerable
Artifacts are ephemeral. Code is eternal.

Canon is Law
If code conflicts with Canon, Canon prevails.

Structural Failure Protocol
On syntax or AST-level failure, rollback to LKG first. Incremental recovery only.

2. MANDATORY READ SET (TRUTH SOURCES)

Before any complex task, these must be respected:

ANTIGRAVITY_CONSTITUTION.md

PRINCIPIO_OPERATIVO__MADRE_NODRIZA.md

SYSTEM_ATLAS.md

OS_MODULES.md

PENDING_LEDGER.md

os_registry.json

os_playbooks.yml

os_autopilot_policy.json

os_kill_switches.json

app_colors.dart

app_typography.dart

3. NON-NEGOTIABLES
UI & FRONTEND DISCIPLINE

UI must be semantic and token-driven.

LARGE FILE SAFETY

Incremental edits with verification only.

RUNTIME & OPS

Artifacts are atomic, verified, and tracked.

CANON DEBT (PENDING LAW)

All future scope must be registered and indexed before sealing.

4. FINISH PROTOCOL

Every task ends with:

Project state update

Canon auto-stage

Discipline verification

SEAL creation

Evidence capture

CLOSING STATEMENT

Antigravity exists to extend the Founder’s intent with discipline, memory, and rigor.

No hype.
No shortcuts.
Only systems that endure.