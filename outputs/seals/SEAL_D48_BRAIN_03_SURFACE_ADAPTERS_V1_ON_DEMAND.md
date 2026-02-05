# SEAL: D48.BRAIN.03 — Surface Adapters V1 (On-Demand)

**Date:** 2026-01-28
**Author:** Antigravity (Agent)
**Authority:** D48.BRAIN.03
**Status:** SEALED

## 1. High-Level Summary
Implemented a strongly-typed Adapter Layer (`OnDemandAdapter`) for the On-Demand Surface.
Moved fragile JSON parsing logic out of `OnDemandPanel`'s build method into a dedicated, testable transformation layer.
This ensures `TimeTravellerChart`, `ReliabilityMeter`, `IntelCards`, and `TacticalPlaybook` receive validated ViewModels, preventing runtime crashes due to missing keys or type mismatches.

## 2. Manifest of Changes

### New Components
- **Adapter Logic:** `market_sniper_app/lib/adapters/on_demand/on_demand_adapter.dart`
- **View Models:** `market_sniper_app/lib/adapters/on_demand/models.dart` (Pure Dart, No Flutter dependency in models)
- **Tests:** `market_sniper_app/test/adapter_smoke_test.dart`

### Refactored Components
- **Consumer:** `market_sniper_app/lib/screens/on_demand_panel.dart`
  - Replaced inline `StandardEnvelope.rawPayload` extraction with `OnDemandAdapter.fromEnvelope(env)`.
  - Updated widget builders to consume `TimeTravellerModel`, `ReliabilityModel`, `IntelDeckModel`, `TacticalModel`.

### Verification Code
- **Build:** `flutter build web` (PASS)
- **Analysis:** `flutter analyze` (PASS - 0 issues in target files)
- **Smoke Test:** `flutter test test/adapter_smoke_test.dart` (PASS)

## 3. Governance
- **Type Safety:** All UI components now strictly typed.
- **Null Safety:** Adapter guarantees non-null models (using Empty/Calibrating fallbacks).
- **Separation of Concerns:** UI only renders. Adapter only parses.

## 4. Pending Closure Hook
- **Resolved Items:** None
- **New Pending Items:** None

---
*Seal authorized by Antigravity Protocol.*

## Pending Closure Hook
- Resolved Pending Items:
  - None
- New Pending Items:
  - None
