# SEAL: D39.HF01 - Web Shell Visibility Hotfix
**Date:** 2026-01-17
**Author:** Antigravity (Agent)
**Authority:** D39.HF01 (Hotfix)
**Strictness:** HIGH
**Target:** Web Layout Constraints

## 1. Summary
This seal certifies the fix for the **Web Shell Blank Body** issue. Layout structure was refactored to enforce explicit constraints.
- **Problem**: `Scaffold` body logic in Flutter Web led to collapsed content height when using `IndexedStack` inside `Scaffold`.
- **Fix**: Replaced `Scaffold` header/footer properties with a manual `Column -> Expanded(Body)` structure inside a `Stack`.
- **Bonus**: Added Founder-only "Shell Proof Overlay" for runtime validation.

## 2. Policy
- **Layout Rule**: Main content must be wrapped in `Expanded` within a `Column`.
- **Debug**: Founder builds show "SHELL OK" overlay.

## 3. Implementation
- **Layout**: `market_sniper_app/lib/layout/main_layout.dart`
- **Verifier**: `flutter analyze` PASS, `flutter build web` PASS.

## 4. Verification
- **Runtime Proof**: `outputs/runtime/day_39/day_39_hf01_web_shell_visibility_proof.json`.
- **Sanity**: Structure guarantees constraints are passed down to children.
- **Discipline**: PASSED.

## 5. D39.HF01 Completion
Web shell visibility is restored.
