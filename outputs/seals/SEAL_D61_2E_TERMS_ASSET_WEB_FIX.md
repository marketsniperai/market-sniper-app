# SEAL: D61.2E TERMS ASSET WEB FIX

> **Authority:** ANTIGRAVITY
> **Date:** 2026-02-07
> **Status:** SEALED

## 1. Summary
This seal certifies the resolution of the 404 error for `terms.md` in Flutter Web.
- **Root Cause:** The `assets/legal/` directory was missing from `pubspec.yaml`, so `terms.md` was not bundled.
- **Fix:** Added `assets/legal/` to the assets list in `pubspec.yaml`.
- **Verification:**
    - `welcome_screen.dart` correctly references `assets/legal/terms.md`.
    - File exists physically at `market_sniper_app/assets/legal/terms.md`.
    - `flutter pub get` executed successfully.

## 2. Changes
- **Configuration:** `market_sniper_app/pubspec.yaml`
- **Logic:** `market_sniper_app/lib/screens/welcome_screen.dart` (Verified correct path)

## 3. Deployment
- **Action:** Restart `flutter run -d chrome` to pick up the new asset bundle.

---
**Signed:** Antigravity
