# SEAL_HOTFIX_WARROOM_WEB_01

**Date**: 2026-01-23
**Author**: Antigravity
**Task**: HOTFIX.WARROOM.WEB.01
**Related**: LAYOUT_POLICE_VIOLATION, MISSING_PLUGIN_EXCEPTION

## 1. Objective
Fix runtime crashes (MissingPluginException) and layout overflows (RenderFlex) on Flutter Web for War Room / CommandCenter.

## 2. Changes
- **Web Storage Guard**: `DayMemoryStore` and `SessionThreadMemoryStore` now detect `kIsWeb`. On Web, they use an in-memory Map fallback instead of calling `path_provider`, preventing crashes.
- **SessionWindowStrip Layout Fix**: Wrapped the Right-Side Status Row (Time/Status) in `SingleChildScrollView(scrollDirection: Axis.horizontal)`. This resolves the "RenderFlex overflowed by 169 pixels" violation on narrower screens or web viewports.

## 3. Verification
- **Static Analysis**: `flutter analyze` passed (115 issues, zero errors).
- **Runtime**: `flutter run -d chrome` launched successfully without crashing on storage init.
- **Layout**: Horizontal overflow in `SessionWindowStrip` is now handled by scrolling (failsafe).

## 4. Artifacts
- **Proof**: `outputs/proofs/hotfix/warroom_web_store_and_layout_fix_proof.json`
- **Git Head**: `HEAD`

## 5. Sign-off
**STATUS**: SEALED
**INTEGRITY**: WEB-SAFE
