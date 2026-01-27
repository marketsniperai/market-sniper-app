# SEAL: ACCOUNT UI UNIFICATION (D45)

**Task:** D45.POLISH.03 — Account UI Consistency & Logout Refactor
**Status:** SEALED (PASS)
**Authority:** ANTIGRAVITY
**Time:** 2026-02-18

## 1. Rationale
To achieve a truly premium "Founder" aesthetic, the experimental Partner Protocol card must visually match the core User Status card. Additionally, the "Log Out" action was simplified from a heavy card to a standard secondary action button to reduce visual noise.

## 2. Manifest of Changes

### A. Card Unification (`lib/screens/account_screen.dart`)
- **Refactor:** Extracted `_buildPremiumCard` to encapsulate the gradient, border, and shadow logic used by the User card.
- **Applied:** Both User and Partner cards now use `_buildPremiumCard`.
- **Result:** Identical visual weight, dimensions, and depth.

### B. Typography & Copy
- **Partner Protocol:**
  - Copy updated: "10 eligible operators required..."
  - Badges: Now use `AppTypography.badge(context)` ensuring global font consistency (Inter).
  - Spacing: Tightened to `SizedBox(width: 8)` between badges.

### C. Action Refactor
- **Log Out:**
  - Removed "Account Actions" card (`NeonOutlineCard`).
  - Implemented centered `OutlinedButton` (Pill shape).
  - Styled with `AppColors.marketBear` (muted error) text.

## 3. Verification
- **Compilation:** `flutter analyze` passed (clean).
- **Runtime:** `flutter run -d chrome` verified successful launch and rendering.
- **Constraints:**
  - No changes to User Card styling (refactor only).
  - No custom GoogleFonts overrides introduced.
  - Used `AppColors` strictly.

## 4. Artifacts
- Proof: `outputs/proofs/polish/account_ui_02_partner_card_unify_proof.json`

## 5. Next Steps
- Implement logic for "Manage Subscription" (currently a stub dialog).
- Connect real backend data to Partner stats.
