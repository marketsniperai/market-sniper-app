# SEAL: D39.01B — CORE20 Canon Correction (Restore VIX)
**Date:** 2026-01-17
**Author:** Antigravity (Agent)
**Authority:** D36.1 (Documentation Governance)

## 1. Summary
Restored **VIX** to the CORE20 Universe to support Volatility tracking, while maintaining the strict 20-symbol limit by removing `US2Y`. Strict alias and validation rules from D39.01A are preserved.

## 2. Changes
- **Core20Universe**:
  - **Added**: `VIX` (Volatility) - Restored as essential market sniper indicator.
  - **Removed**: `US2Y` (Rates) - Removed to maintain 20-symbol cap. `US10Y` remains as the canonical rate benchmark.
  - **Aliases**: Removed `US02Y` alias mapping. `BTC` aliases preserved.
  - **Logic**: Strict normalization (No displayLabel matching) preserved.

## 3. Verification results
- **Discipline**: `verify_project_discipline.py` **PASSED**.
- **Analysis**: `flutter analyze` **PASSED**.
- **Runtime Proof**: `day_39_01B_core20_validator_proof.json`:
  - Count: 20 (PASSED)
  - VIX: Valid (PASSED)
  - US2Y: Invalid (PASSED)
  - AAPL: Invalid (PASSED)

## 4. Updates
- Corrects D39.01A canon to align better with Dashboard requirements (Volatility > Short Duration Rates).
