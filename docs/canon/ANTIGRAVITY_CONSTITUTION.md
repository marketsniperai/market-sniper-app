ANTIGRAVITY CONSTITUTION

Status: SUPREME LAW
Enforcement: AUTOMATED (verify_project_discipline.py)

1. PRIME DIRECTIVES (NON-NEGOTIABLE)

One Step = One Seal
No task concludes without a verifiable SEAL_*.md.

Core OS Changes Require Release Discipline
Any modification under backend/os_ops/ MUST include RELEASE_CHECKLIST.md evidence.

Separation of Powers

AGMS reasons

Autofix executes

Policy arbitrates
No role leakage is allowed.

Source is Sacred. Runtime is Regenerable

Code is permanent

Runtime artifacts are ephemeral

outputs/runtime/ is NEVER committed

Canon is Law
If code conflicts with Canon, code is wrong.

Structural Failure Protocol (LKG First)
If any syntax or AST-level failure occurs (e.g. parser errors, missing build(), unmatched braces):

Immediate rollback to Last Known Good (LKG)

Re-apply changes incrementally

Verify after each increment
🚫 Patch-on-top recovery is PROHIBITED in this state.

2. MANDATORY READ SET (SOURCE OF TRUTH)

Before starting any non-trivial task, Antigravity MUST respect these if present:

Canon & System

docs/canon/ANTIGRAVITY_CONSTITUTION.md

docs/canon/PRINCIPIO_OPERATIVO__MADRE_NODRIZA.md

docs/canon/SYSTEM_ATLAS.md

docs/canon/OS_MODULES.md

docs/canon/PENDING_LEDGER.md

Machine & Policy

os_registry.json

os_playbooks.yml

os_autopilot_policy.json

os_kill_switches.json

UI Truth

market_sniper_app/lib/theme/app_colors.dart

market_sniper_app/lib/theme/app_typography.dart

3. NON-NEGOTIABLE DISCIPLINE
A. UI & FRONTEND

🚫 PROHIBITED: Hardcoded colors (Color(0x...), Colors.red, etc.)

✅ Use AppColors.semanticToken

🚫 PROHIBITED: Custom TextStyle

✅ Use AppTypography.*

UI must be semantic, token-driven, and theme-authoritative.

B. LARGE FILE SAFETY (≥ 300 LOC)

For Dart files over 300 LOC, ONE of the following is mandatory:

Block-level edits only (clearly delimited), OR

Git rollback to LKG + incremental re-application

🚫 PROHIBITED:
Multi-feature patching without intermediate compile/verify steps.

Minimum requirement:

Compile / analyze after each structural change

C. RUNTIME & OPS HYGIENE

🚫 PROHIBITED: Committing outputs/runtime/

✅ MANDATORY: Proof artifacts go in outputs/proofs/

✅ MANDATORY: Update PROJECT_STATE.md at task end

✅ MANDATORY: Create a SEAL in outputs/seals/

Artifacts must be atomic, verifiable, and traceable.

D. CANON DEBT (PENDING LAW — STRICT)

If a SEAL contains any of the following:

“Next Steps”

“Future”

“Planned”

“Pending”

“Upgrade”

Then ALL are mandatory:

Update docs/canon/PENDING_LEDGER.md

Update the corresponding pending index JSON
(e.g. outputs/proofs/canon/pending_index_*.json)

Pending Closure Hook MUST include:

Resolved Pending Items

New Pending Items

❌ FAILURE CONDITION:
If pending artifacts are not updated → SEAL IS INVALID

4. FINISH PROTOCOL (MANDATORY ORDER)

Every task ends with ALL of the following:

Update PROJECT_STATE.md

Run python tool/auto_stage_canon_outputs.py

Run verify_project_discipline.py

Create outputs/seals/SEAL_*.md

Generate proof artifacts in outputs/proofs/

No exceptions. No shortcuts.

5. OPERATING PRINCIPLE (CLOSING LAW)

Antigravity exists to extend the Founder’s intent with:

Discipline

Memory

Rigor

No hype.
No shortcuts.
Only systems that endure.

📌 EFFECTIVE DATE

Original Constitution + Updates consolidated and enforced as of 2026-02-05