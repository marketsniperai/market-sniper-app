# Implementation Plan - Account Flip Interaction (D45.POLISH.03)

## Goal
Implement a "flip" interaction for the Partner Protocol card on the Account Screen to reveal detailed program terms.

## Proposed Changes

### [market_sniper_app]

#### [MODIFY] [account_screen.dart](file:///c:/MSR/MarketSniperRepo/market_sniper_app/lib/screens/account_screen.dart)
- **Refactor:** Extract `_buildPremiumCard` logic into a reusable `_PremiumCardShell` stateless widget class (private, at bottom of file).
- **New Widget:** Implement `_FlipCard` (StatefulWidget) locally.
  - Uses `AnimationController` and `Transform` (Matrix4.rotationY).
  - Handles tap to flip.
  - Duration: 300ms.
- **New Content:** Implement `_PartnerProtocolBack` content.
  - Title: "Partner Protocol"
  - Bullets: Invite trusted operators, 10 eligible members, governed by terms.
  - Mini Tier Strip.
  - Footnote.
  - "Terms" button.
- **Integration:** Update `_buildPartnerProtocolCard` to return `_FlipCard` with:
  - **Front:** Existing Partner Protocol content (wrapped in `_PremiumCardShell`).
  - **Back:** New Back content (wrapped in `_PremiumCardShell`).

## Verification Plan

### Automated
- Run `flutter analyze`.

### Manual Verification
- Run `flutter run -d chrome`.
- Verify:
  - Tap Partner Protocol card -> Flips smoothly to back.
  - Front/Back have identical dimensions and shell styling.
  - Back content matches text requirements.
  - "Terms" button functionality works on back.
  - Tap again -> Flips back to front.
