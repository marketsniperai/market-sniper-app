# SEAL: D61.x.02 — COMMAND CENTER TOOLTIP EXPANSION (COLLAPSIBLE SECTIONS)

**Date**: 2026-02-07
**Author**: Antigravity (Agent)
**Status**: SEALED
**Related**: D61.x, D61.1

---

## 1. Objective
Expand the Coherence Quartet Tooltip to support a "Deep Dive" information architecture without introducing new screens.
- **Internal Stack**: Collapsible sections for Why High Confidence, Evidence Memory, and Regime/Macro/Options.
- **External Support**: Stubbed sections for Capital Activity and Human Consensus (Logic-Ready).

## 2. Changes Implemented

### A. CoherenceQuartetTooltip (UI)
- **Collapsible Layout**: Implemented `AnimatedCrossFade` for smooth expand/collapse.
- **Internal Stack**: Default **EXPANDED**. Contains:
    - Why High Confidence (Cyan bullets)
    - Evidence Memory (Primary text)
    - Regime / Macro / Options (Secondary text)
- **External Support**: Default **COLLAPSED**.
    - Stubbed with "N/A (External source unplugged)" or local feature flags (`kEnableCapitalActivity`).
- **Risk Strip**: Added a dedicated, always-visible warning strip at the top if `invalidationRisk` is present.

### B. CoherenceQuartetCard (Data)
- **Rich Mock Data**: Updated `_getMockData` to fully populate the new schema.
- **Wiring**: Updated `_buildChip` to pass the structured data to the tooltip.

## 3. Verification
- **Static Analysis**: `flutter analyze` passed with **0 issues**.
- **Contract**: Defined in `outputs/proofs/D61_X_02_TOOLTIP/tooltip_contract.json`.

## 4. Artifacts
- `outputs/proofs/D61_X_02_TOOLTIP/tooltip_contract.json`
- `outputs/proofs/D61_X_02_TOOLTIP/contract_example_internal_only.json`
- `outputs/proofs/D61_X_02_TOOLTIP/contract_example_with_external_stub.json`

---
**SEALED BY ANTIGRAVITY**
