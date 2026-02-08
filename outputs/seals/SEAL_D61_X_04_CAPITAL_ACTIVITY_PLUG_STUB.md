# SEAL: D61.x.04 CAPITAL ACTIVITY PLUMBING (STUB)

**Date:** 2026-02-07
**Author:** Antigravity (Agent)
**Status:** SEALED

## 1. Objective
Implement the "ready-to-plug" service layer for Capital Activity (and Human Consensus) without enabling any paid APIs or keys.

## 2. Implementation

### 2.1 Service Layer (`lib/services/external_support/`)
- **Provider Interface:** `CapitalActivityProvider` abstract class.
- **Model:** `CapitalActivityResult` with `CapitalActivityStatus` (unplugged, mock, live).
- **Default State:** Factory `CapitalActivityResult.unplugged()` ensures N/A state by default.
- **Mock Implementation:** `MockCapitalActivityProvider` returns educational/deterministic data.
- **Repository:** `CapitalActivityRepository` with basic in-memory caching and debug flag support (`EXTERNAL_SUPPORT_MOCK`).

### 2.2 UI Integration (`coherence_quartet_tooltip.dart`)
- **Status Aware:** Tooltip now reads `status` field (Unplugged vs Mock vs Live).
- **Consolidated Logic:** 
  - `UNPLUGGED` -> Displays grayed out "N/A (External source unplugged)".
  - `MOCK` -> Displays yellow badge "MOCK" + Summary + Bias.
- **Safety:** Defaults to UNPLUGGED if data is missing or malformed.

## 3. Verification

### 3.1 Automated Analysis
`flutter analyze` passed with **0 issues**.
Target files:
- `lib/services/external_support/`
- `lib/widgets/command_center/coherence_quartet_tooltip.dart`

### 3.2 Proofs
- **Contract:** `outputs/proofs/D61_X_04_EXTERNAL_PLUG/external_support_contract.json`

## Pending Closure Hook

### Resolved Pending Items:
- [x] Create `CapitalActivityProvider` (Abstract + Model).
- [x] Create `MockCapitalActivityProvider` (No API).
- [x] Create `CapitalActivityRepository` (Caching).
- [x] Update Tooltip UI (UNPLUGGED / MOCK States).

### New Pending Items:
- None.

## Sign-off
This seal confirms the successful "Stub Wiring" of the automated institutional support layer. The system is plumbed but remains cost-neutral and unplugged until specific activation.
