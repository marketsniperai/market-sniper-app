# SEAL: D47.HF27 — Tactical Playbook (Watch / Invalidate)

**Type:** HOTFIX / FEATURE (D47 Arc)
**Status:** SEALED (PASS)
**Date:** 2026-01-28
**Author:** Antigravity

## 1. Objective
Implement "Tactical Playbook" (Watch / Invalidate) block in On-Demand Dossier.
Features:
- **Watch For:** Bullets derived from Evidence (Win Rate), Options (Vol Mode), News (Activity).
- **Invalidated If:** Bullets derived from standard risk logic.
- **Daily Lock:** Overrides with "Calibration Window" context during 09:30-10:30 ET.
- **UI:** Dark block with Green/Red accents.

## 2. Changes
- **Backend:** `backend/os_intel/projection_orchestrator.py`
    - Added `tactical` block generator (Watch/Invalidate derivation).
- **New Widget:** `lib/widgets/tactical_playbook_block.dart`
    - Logic-free UI component.
- **Modified:** `lib/screens/on_demand_panel.dart`
    - Integrated `TacticalPlaybookBlock` below `IntelCards`.
    - Added Daily Lock override logic for bullets.

## 3. Verification
- **Static Analysis:** Passed (`flutter analyze`).
    - Proof: [`01_flutter_analyze.txt`](../../outputs/proofs/day47_hf27_tactical_playbook/01_flutter_analyze.txt)
- **Compilation:** Passed (`flutter build web`).
    - Proof: [`02_flutter_build_web.txt`](../../outputs/proofs/day47_hf27_tactical_playbook/02_flutter_build_web.txt)
- **Logic:** Verified via code inspection and runtime note.
    - Proof: [`04_runtime_note.md`](../../outputs/proofs/day47_hf27_tactical_playbook/04_runtime_note.md)

## 4. Artifacts
Directory: `outputs/proofs/day47_hf27_tactical_playbook/`
- `00_diff.txt`
- `01_flutter_analyze.txt`
- `02_flutter_build_web.txt`
- `03_runtime_screenshots_SKIPPED.txt`
- `04_runtime_note.md`
- `05_sample_payload.json`

## 5. Next Steps
- HF30: Full Gating mechanics.

## Pending Closure Hook
- Resolved Pending Items:
  - None
- New Pending Items:
  - None
