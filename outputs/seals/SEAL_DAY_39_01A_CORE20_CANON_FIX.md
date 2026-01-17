# SEAL: D39.01A — CORE20 Canon Fix (20 Symbols & Strict Aliases)
**Date:** 2026-01-17
**Author:** Antigravity (Agent)
**Authority:** D36.1 (Documentation Governance)

## 1. Summary
Hardened the CORE20 definition to strictly enforcing the 20-symbol count (removing VIX) and replaced permissive `displayLabel` matching with a strict `alias` map.

## 2. Changes
- **Count Fix**: Reduced count from 21 to 20 by removing `VIX` (Volatility) from canonical set, aligning with the "CORE20" name.
- **Strict Validation**:
  - Implemented `aliases` map (`BTC` -> `X:BTCUSD`, `BTCUSD` -> `X:BTCUSD`).
  - Removed implicit matching by `displayLabel`.
  - Added `normalizeSymbol` method to `Core20Universe`.
- **Runtime Proof**: Generated `day_39_01_core20_validator_proof.json` verifying:
  - Valid canonicals (SPX) pass.
  - Valid aliases (BTC) normalize correctly.
  - Invalid symbols (AAPL) fail.
  - Count is exactly 20.

## 3. Verification results
- **Discipline**: `verify_project_discipline.py` **PASSED**.
- **Analysis**: `flutter analyze` **PASSED** (Stale errors cleared).
- **Runtime Proof**:
  - Count: 20
  - Compliance: PASS

## 4. Updates
- Aligns D39.01 implementation with strict governance requirements.
