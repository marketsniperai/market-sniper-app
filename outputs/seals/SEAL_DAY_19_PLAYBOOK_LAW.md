# SEAL DAY 19: PLAYBOOK LAW

**Authority**: CANONICAL
**Effective**: Day 19 (Titanium)
**Scope**: All OS Modules

## I. The Law of Determinism
1. **No Feature Ships Without a Playbook**: Every new OS failure mode or maintenance requirement MUST optionally have a generic default, but ideally has a specific entry in `os_playbooks.yml`.
2. **Contracts Are Binding**: Modules must declare their artifact and endpoint contracts in `os_module_contracts.json`.
3. **Autofix Is Deterministic**: Steps taken by Autofix must be traceable to a specific Playbook ID and Action Code.
4. **Append-Only History**: Playbooks are immutable. Deprecations must be explicit. Ledger history must never be rewritten.

## II. Shadow Repair Safety
1. **Propose Only**: The Shadow Repair subsystem is forbidden from modifying source code or applying checks. It constructs `patch_proposal.json` ONLY.
2. **Founder Gate**: Use of Shadow Repair requires explicit Founder Authorization (Key).

## III. War Room Visibility
1. **Drift Is Public**: Any deviation from `os_module_contracts.json` must be visible in the War Room Truth Compare panel.
2. **Playbook Trace**: Every automated action must link back to a matched Playbook in the War Room Timeline.
