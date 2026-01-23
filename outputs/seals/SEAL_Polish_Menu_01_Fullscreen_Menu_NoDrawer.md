
# SEAL: Polish.Menu.01 - Fullscreen Menu Replacement

## 1. Summary
The lateral `Drawer` navigation has been replaced by a fullscreen `MenuScreen`. This provides a more premium, dedicated surface for app navigation and settings, consistent with the "Market Sniper" aesthetic.

## 2. Changes
- **Removed**: `Drawer` widget from `MainLayout`.
- **Added**: `lib/screens/menu_screen.dart` implementing:
  - Fullscreen layout with custom `AppBar`.
  - Stub Toggles: Notifications, Human Mode.
  - Actions: Premium Protocol, Share Attribution (Founder Only - Gated).
  - Modals: "About Us" and "Legal" with dark scrim and centered card.
- **Modified**: `MainLayout` hamburger icon now pushes `MenuScreen` via `Navigator`.

## 3. Superseded Architecture
The following seals referenced the now-removed Drawer and have been marked with a `SUPERSEDED` note:
- `SEAL_DAY_45_05_PREMIUM_FEATURE_MATRIX.md` (Menu Entry)
- `SEAL_DAY_45_12_SHARE_ATTRIBUTION_DASHBOARD.md` (Founder Access)

## 4. Verification
- **Hamburger Tap**: Opens `MenuScreen` (Fullscreen).
- **Close Button**: Returns to Dashboard.
- **Premium Protocol**: Navigates correctly.
- **Founder Link**: Visible only in Founder Build (Debug/Founder Env), navigates to Share Dashboard.
- **About/Legal**: Open responsive modals.

## 5. Next Steps
- Implement actual logic for "Notifications" and "Human Mode" toggles (currently stubs).

## 6. Hotfix Verification (GoogleFonts)
- **Issue**: Compilation failure due to deprecated/incorrect accessor `GoogleFonts.jetbrainsMono`.
- **Fix**: Renamed to `GoogleFonts.jetBrainsMono`.
- **Status**: Verified via `flutter analyze` and Hotfix workflow.

