# SEAL: MENU SCREEN UI REFINE (POLISH.MENU.UI.01)
> **ID:** SEAL_POLISH_MENU_UI_01
> **Date:** 2026-01-24
> **Author:** Antigravity (Agent)
> **Status:** SEALED

## 1. Context
The Menu Screen required a visual upgrade to match the "Premium Institutional" design language, moving away from a card-heavy interface to a cleaner, refined settings list aesthetic.

## 2. Changes
- **Typography:** Unified all text (Headers, Items, Toggles) to `GoogleFonts.inter`. Removed `JetBrainsMono` usage in UI elements (except subtle version text).
- **Proportions:**
  - Reduced row padding to achieve ~48px touch targets (compact density).
  - Increased top spacing for Section Headers to improve visual separation.
- **Styling:**
  - Removed `AppColors.surface1` fill from rows for a transparent, cleaner look.
  - Softened borders to `AppColors.borderSubtle.withOpacity(0.3)`.
  - Replaced back arrow with `arrow_back_ios_new` and item arrows with smaller `arrow_forward_ios`.
- **Debug:** De-emphasized the "Founder Routing" button (smaller text, transparent background).

## 3. Constraints Verified
- **Logic:** ZERO changes to navigation routing, switch logic, or permissions.
- **Assets:** No new font files added.
- **Colors:** Used existing palette with opacity adjustments only.

## 4. Verification
- **Runtime:** `flutter run -d chrome` verified layout density and typography unification.
- **Codebase:** `flutter analyze` passed.

## 5. Conclusion
The Menu Screen now adheres to a refined, distraction-free institutional aesthetic, improving clarity and visual calm while maintaining full functionality.
