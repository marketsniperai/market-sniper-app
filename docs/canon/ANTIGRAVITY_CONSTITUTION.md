# ANTIGRAVITY CONSTITUTION
**Status:** SUPREME LAW
**Enforcement:** AUTOMATED (verify_project_discipline.py)

## 1. Prime Directives
1.  **"One Step = One Seal"**: No day ends without a SEAL file.
2.  **"No Core OS Change Without Release Checklist"**: Modifying `backend/os_ops/` requires `RELEASE_CHECKLIST.md` evidence.
3.  **"AGMS Thinks. Autofix Acts. Policy Decides."**: Respect the Separation of Powers.
4.  **"Source is Sacred. Runtime is Regenerable."**: `outputs/runtime/` is ephemeral. Code is eternal.
5.  **"Canon is Law"**: If the Code contradicts Canon, the Code is wrong.

## 2. Mandatory Read Set (The "Truth")
*Before answering complex queries or starting a task, Antigravity MUST verify if these files exist and respect them:*
- `docs/canon/ANTIGRAVITY_CONSTITUTION.md` (This file)
- `docs/canon/PRINCIPIO_OPERATIVO__MADRE_NODRIZA.md` (Operational Core)
- `docs/canon/SYSTEM_ATLAS.md` (Map)
- `docs/canon/OS_MODULES.md` (Module Registry)
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

### Runtime & Ops
- **PROHIBITED:** Committing files in `outputs/runtime/` to git (should be ignored).
- **MANDATORY:** `PROJECT_STATE.md` must be updated at the end of every Task.
- **MANDATORY:** `outputs/seals/` must be created to close a Task.

## 4. Finish Protocol
*Every Task concludes with this sequence:*
1.  **Update State:** Edit `PROJECT_STATE.md`.
2.  **Verify Discipline:** Run `verify_project_discipline.py`.
3.  **Seal:** Create `outputs/seals/SEAL_*.md`.
4.  **Evidence:** Generate logs in `outputs/runtime/`.
