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

E. HUMAN-FIRST DISCIPLINE (HF-1)

Public Copy must be "Human-First":
- Primary Headings: Clear, benefit-driven language.
- Secondary/Tags: Technical engine names (e.g. Coherence Quartet).
- Subordinated: Diagnostics and raw metrics.

Friction Reduction:
- No toggles for "Human Mode" in public interfaces.
- High-context is the DEFAULT and ONLY state for public users.

Founder Exception:
- War Room and Founder tools retain raw technical labels for precision.

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

6. SNAPSHOT-FIRST UI LAW (SSOT ENFORCEMENT)

Status: ABSOLUTE LAW
Enforcement: AUTOMATED (verify_snapshot_only.ps1)

A. READ PATH SINGLETON
All UI read operations MUST originate from UnifiedSnapshotRepository.

B. NO NETWORK IN UI
Screens and Widgets are forbidden from:
- Importing ApiClient for read operations
- Performing HTTP calls
- Calling legacy endpoints

C. SNAPSHOT CONTRACT DECLARATION
Every new feature must declare:
- Snapshot paths consumed
- Fallback behavior
- "UNAVAILABLE" policy

D. UNAVAILABLE IS VALID
Missing snapshot data results in:
- UNAVAILABLE state
- NEVER fallback network calls

E. WRITE SURFACE EXCEPTION
Only explicitly declared write operations may call ApiClient directly.
Must live under: lib/services/write_surface/*

7. ARTIFACT PRESERVATION LAW (NO DELETE WITHOUT FOUNDER AUTHORIZATION)

Status: ABSOLUTE LAW
Enforcement: AUTOMATED (verify_no_delete.ps1)

A. IMMUTABILITY PRINCIPLE
No file, widget, module, logic block, or artifact may be deleted without explicit Founder instruction.

B. DEPRECATION OVER DELETION
Instead of deletion:
- Mark as DEPRECATED
- Isolate
- Comment
- Guard behind flag
But DO NOT REMOVE.

C. FOUNDER AUTHORITY REQUIRED
Any delete operation requires:
- Explicit instruction from Founder
- Reference to specific file
- Justification
- Seal documenting removal

D. GIT SAFETY RULE
Before any commit:
- Run git status
- If files show as deleted (D), abort commit unless Founder explicitly approved.

E. RECREATION BAN
If a file previously existed and is missing:
- Investigate history
- Restore from git
- DO NOT recreate from memory
This prevents historical drift.

8. ROOT-ANCHORED DOCTRINE (EXECUTION LAW)

Status: ABSOLUTE LAW
Enforcement: AUTOMATED (verify_repo_root.py)

A. ANCHOR REQUIRED
All git, path, and tooling operations MUST start from `git rev-parse --show-toplevel`.
CWD must string-equal Git Toplevel.

B. SUBFOLDER BAN
Execution from subdirectories (e.g. `market_sniper_app/`, `backend/`) is PROHIBITED.
Reason: Pathspec ambiguity and tooling blindness.

C. ABORT ON DRIFT
If CWD != Root: Tooling MUST abort immediately with explicit error and fix instructions.

9. ARTIFACT PRESERVATION LAW V2 (APPEND-ONLY)

Status: ABSOLUTE LAW
Enforcement: AUTOMATED (verify_artifact_integrity.py)

A. APPEND-ONLY OUTPUTS
`outputs/seals/*` is APPEND-ONLY.
Modification of existing seals is PROHIBITED.
Deletion of seals is PROHIBITED.

B. DELETE AUTHORIZATION
Any deletion, move, or rename of `outputs/seals/*` requires:
1. `FOUNDER_DELETE_APPROVAL.txt` present in root.
2. Explicit entry in an allowlist.

C. STASH SAFETY
Stashing `outputs/seals` or `outputs/proofs` is PROHIBITED unless a "stash manifest" is committed first.
Risk: Silent loss of uncommitted forensic evidence.

10. CANON DISCIPLINE LAW V2 (DERIVED TRUTH)

Status: ABSOLUTE LAW
Enforcement: AUTOMATED (verify_canon_sync.py)

A. DERIVED WAR CALENDAR
The War Calendar (`OMSR_WAR_CALENDAR__35_55_DAYS.md`) must be reconciled deterministically from the Seals Index.
It is a DERIVED artifact, not a primary source.

B. SYNC PROOF
Every update to the War Calendar must includes a "Sync Proof" verifying that every entry links to a valid Seal on disk.

11. NO GHOST DRAFTS RULE

Status: ABSOLUTE LAW

A. COMMIT OR DIE
Any documentation-only roadmap (like D63) MUST be committed with proof immediately upon creation.

B. LOCAL-ONLY BAN
"Drafting" complex canon in a local-only file without a commit is PROHIBITED.
If it's not in Git, it doesn't exist.
