# SEAL_D53_6Y_TRUTH_COVERAGE_METER

## 1. Description
This seal certifies the implementation of the **Truth Coverage Meter** (D53.6Y) in War Room V2.
This Founder-only surface provides instant, quantifiable visibility into the "Institutional Truth" of the system, displaying fetch health, data freshness (Age), and real vs. expected tile coverage.

## 2. Objectives Met
- **Founder Only**: Visible only when `AppConfig.isFounderBuild` is true.
- **No Backend Changes**: Pure client-side derivation from `WarRoomSnapshot`.
- **Meter UX**: Compact, monospaced traffic-light design:
  `[FETCH: OK] [AGE: 3s] [COV: 18/25 (72%)] [N/A: 7]`
- **Missing Inventory**: Explicitly lists missing (N/A) tiles below the meter (e.g., `MISSING: OPTIONS, MACRO...`).

## 3. Implementation Details
- **Logic**: `war_room_truth_metrics.dart`
  - Defines `TruthMetricResult` with `coveragePct` and `topNaTiles` (limit 5).
  - Explicit registry of 25 canonical tiles (OS, ALPH, IRON, TIER1, etc.).
- **UI**: `ConsoleGates.dart` (Zone 4)
  - injects `_buildTruthPanel()` at the top of the zone.
  - Uses `GoogleFonts.robotoMono` for density.
  - Colors: Cyan (OK), Orange (Degraded/Partial), Red (Stale/Error), Gray (Inactive).

## 4. Verification
- **Compilation**: `flutter analyze` passing (0 errors).
- **Runtime**: `flutter run -d chrome` renders Zone 4 with the meter.
- **Observability**: `WAR_ROOM_TRUTH_METRICS` log line emitted per build.

## 5. Metrics Formula
- **Real Count**: Count of tiles where `isAvailable == true`.
- **Total Count**: 25 (Canonical Inventory).
- **Coverage %**: `(Real / Total) * 100`.
- **Age**: Seconds since `snapshot.universe.timestampUtc`.

## 6. Metadata
- **Date**: 2026-01-31
- **Task**: D53.6Y
- **Status**: SEALED
