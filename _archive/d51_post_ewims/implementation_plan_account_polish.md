# Implementation Plan - Account Screen Polish (D45.POLISH.03)

## Goal
Polish the Account screen UI to a premium, coherent layout with exactly three primary cards: User/Plan, Partner Protocol, and Account Actions. Remove legacy sections and implement specific Partner Protocol UI requirements.

## Proposed Changes

### [market_sniper_app]

#### [MODIFY] [account_screen.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/screens/account_screen.dart)
- Import `NeonOutlineCard`.
- Remove `_WeeklyReviewCardStub` class and usage.
- Remove `_scoreData`, `_weeklyData` variables.
- Remove `streak` calculation.
- **Top Card (User/Plan):** Wrap content in `NeonOutlineCard` (replacing ad-hoc Container/BoxDecoration). Ensure `neonCyan` is used.
- **Partner Protocol Card:**
  - Create new `_PartnerProtocolCard` (or refactor `_buildPartnerSection`).
  - Use `NeonOutlineCard`.
  - Content:
    - **Header:** "Partner Protocol".
    - **Invite Code Row:** Code chip (MS-FOUNDER-888) + Copy/Share icons.
    - **Tier Badges Row:** 4 badges (Collaborator, Entrepreneur, Business Partner, Institutional Partner). Highlight first one.
    - **Progress Line:** "8 more eligible operators to activate Partner Credits."
    - **Actions:** "View Terms" button (navigates to `PartnerTermsScreen`).
- **Account Actions Card:**
  - Create small `NeonOutlineCard`.
  - Move "Log Out" functionality here.
- **Removals:**
  - Remove "Notifications" and "Restore Purchases" tiles.
  - Remove Streak section.

## Verification Plan

### Automated
- Run `flutter analyze` to ensure no errors.

### Manual Verification
- Run `flutter run -d chrome`.
- Login/Navigate to Account Screen.
- Verify:
  - Only 3 cards exist.
  - Top card is User/Plan.
  - Middle card is Partner Protocol (check Tiers, Invite Code, Terms button).
  - Bottom card is Account Actions (Log Out).
  - No Streak, Notifications, or Restore Purchases.
  - Shell bars are visible.
  - Visuals match "Neon Cyan" theme.
