# SEAL_D53_6Z_WAR_ROOM_VIEWPORT_NULL_FIX

## 1. Description
This seal certifies the resolution of the critical "War Room shows nothing" regression and `viewport hitTestChildren` crash (D53.6Z).
The investigation identified a rendering instability in the newly added **Truth Coverage Meter** (D53.6Y), likely due to `Wrap` layout interactions within the `CustomScrollView` / `SliverList` context causing invalid hit-test geometry.

## 2. Root Cause Analysis
- **Symptom**: "FLUTTER_ERROR: Unexpected null value" during `viewport.hitTestChildren`.
- **Vector**: `ConsoleGates` (Zone 4) -> `_buildTruthPanel` -> `Wrap`.
- **Mechanism**: The `Wrap` widget containing complex `Text.rich` spans, when embedded in a `SliverList` via `ConsoleGates`, seemingly produced an invalid RenderObject tree or null child reference during hit testing in the Chrome engine.
- **Route Hijack**: The development convenience of forcing `/war_room` as `initialRoute` (D53.6X) was masking the startup flow and preventing normal navigation checks.

## 3. Resolution
- **UI Hardening**: Replaced the problematic `Wrap` layout in `ConsoleGates` with a strict `Row` + `Expanded` layout. This eliminates the complex intrinsic width calculations of `Wrap` and ensures deterministic constraints.
- **Route Restoration**: Reverted `main.dart` `initialRoute` to `/welcome`, forcing the app to flow through the `StartupGuard` and ensuring the `WarRoom` is entered with valid context.
- **Instrumentation**: Added `WARROOM_BUILD_ENTER` and `WARROOM_SCROLL_ATTACH` logs to `WarRoomScreen` to enable forensic tracking of the render cycle.
- **Safety Wrappers**: Verified `WarRoomScreen` and Zones catch build errors, ensuring a "Gray Screen" or error message instead of a full viewport crash.

## 4. Verification
- **Compilation**: `flutter analyze` passing.
- **Runtime**: `flutter run -d chrome` launches to `/welcome` (Safe Startup).
- **War Room Entry**: Navigation to War Room renders Zone 4 (Truth Meter) without crashing.
- **Logs**: `WARROOM_BUILD_ENTER` confirms build cycle completion.

## 5. Metadata
- **Date**: 2026-01-31
- **Task**: D53.6Z
- **Status**: SEALED
- **Next**: D54.0 (War Room V2 Final)
