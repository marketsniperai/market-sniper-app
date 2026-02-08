# SEAL: D61.x.06B FOUNDER VISIBILITY & UNDERLINE PURGE

**Date:** 2026-02-07
**Author:** Antigravity (Agent)
**Status:** SEALED

## 1. Objective
Fix Command Center visibility for Founder builds (ensure full clarity in debug mode) and purge all decorative underlines to meet premium UI standards.

## 2. Implementation

### 2.1 Founder Visibility Override
- **File:** `screens/command_center_screen.dart`
- **Logic:** Added strict override in `_checkAccess`:
    ```dart
    if (AppConfig.isFounderBuild && kDebugMode) {
      baseTier = CommandCenterTier.elite;
      debugPrint("CC_VISIBILITY: founderDebugOverride=true ...");
    }
    ```
- **Config Fix:** Modified `AppConfig.isFounderBuild` (lib/config/app_config.dart) to remove the blanket `if (kDebugMode) return true` override. Now `isFounderBuild` strictly respects the `FOUNDER_BUILD` environment variable, enabling proper "Public Mode" testing in debug.

### 2.2 Underline Purge
- **File:** `screens/command_center_screen.dart`
    - **FIX:** Wrapped content in `Material(type: MaterialType.transparency)` to solve "double yellow underlines" (Flutter fallback behavior).
    - Confirmed removal of header dividers.
- **File:** `widgets/command_center/coherence_quartet_tooltip.dart`
    - Removed `Divider` widget.
- **File:** `widgets/command_center/market_pressure_orb.dart`
    - **FIX:** Replaced `BackdropFilter` (Blur) in Lens Gloss with `LinearGradient` (White->Transparent) to eliminate visual artifacts while keeping the highlight.

## 3. Verification

### 3.1 Static Analysis
`flutter analyze` passed.

### 3.2 Runtime Proof (Logs)
Validates that the override behaves deterministically based on the `FOUNDER_BUILD` flag.

**Scenario A: Founder Build (`--dart-define=FOUNDER_BUILD=true`)**
- Log: `CC_VISIBILITY: founderDebugOverride=true tier=CommandCenterTier.elite`
- Status: **PASSED** (Orb Fully Visible)

**Scenario B: Public Build (Default)**
- Log: `access_level=CommandCenterTier.free` (PASSED - No Override)

### 3.3 Visual Verification
- **Double Underlines:** ELIMINATED (via Material wrap).
- **Orb Artifacts:** ELIMINATED (via Gradient gloss).

## Pending Closure Hook

### Resolved Pending Items:
- [x] Founder Override: Force ELITE tier for Founder builds (Debug/Release safety).
- [x] Underline Purge: Remove all decorative lines.
- [x] Fix `AppConfig` to allow deterministic "Public Mode" testing.

### New Pending Items:
- None.

## Sign-off
This seal confirms that Founder builds now have a reliable, forced-visibility mode for debugging, and the Command Center UI is free of legacy decorative underlines.
