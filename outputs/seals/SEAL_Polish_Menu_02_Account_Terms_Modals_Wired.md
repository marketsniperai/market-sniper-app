
# SEAL: Polish.Menu.02 - Account & Terms Screens

## 1. Summary
Ported the `AccountScreen` and `PartnerTermsScreen` from legacy LKG files and wired them into the new `MenuScreen`. This implementation replaces the temporary stubs and provides a functional (though partially mocked) account interface.

> [!NOTE]
> This completes the Drawer replacement initiated in `Polish.Menu.01`. The Drawer implementation is fully superseded.

## 2. Changes
- **Account Screen**: `lib/screens/account_screen.dart`
  - Ported complex UI with stubs for `WeeklyReview`, `PartnerBadge`, and Services.
  - Functional layout using `AppConfig.isFounderBuild` for gating.
  - Cleaned up dependencies to run in the new repo without errors.
- **Partner Terms**: `lib/screens/partner_terms_screen.dart`
  - Clean port of the terms disclosure UI.
- **Menu Screen**: 
  - Wired "Account" button to `AccountScreen`.
  - Added "Open Partner Terms" button to the Legal Modal.

## 3. Stubbed Dependencies
To ensure immediate compilation without backend changes, the following were stubbed locally in `account_screen.dart`:
- `ReferralCodeService` / `PartnerTrackingService` -> Logic mocked with SnackBars.
- `WeeklyReviewCard` -> `_WeeklyReviewCardStub`.
- `PartnerBadge` -> `_PartnerBadgeStub`.

## 4. Verification
- **Compilation**: Validated via `test/verify_menu.dart`.
- **Navigation Flow**: Menu -> Account -> Back -> Legal -> Terms.

## 5. Next Steps

## 6. Hotfix (App Compilation)
- **Issue**: `GoogleFonts.jetbrainsMono` caused build errors.
- **Action**: Bulk replaced with `GoogleFonts.jetBrainsMono`.
- **Status**: Resolution confirmed.

