# SEAL: PARTNER PROTOCOL FLIP (D45)

**Task:** D45.POLISH.03 — Partner Protocol Flip Interaction
**Status:** SEALED (PASS)
**Authority:** ANTIGRAVITY
**Time:** 2026-02-18

## 1. Rationale
To provide necessary depth to the Partner Protocol program without cluttering the main dashboard, a "Flip" interaction was implemented. This allows the user to access detailed terms and mechanics on-demand while maintaining the minimal, premium "Founder" aesthetic on the front.

## 2. Manifest of Changes

### A. New Logic (`lib/screens/account_screen.dart`)
- **`_FlipCard` Widget:** A local, zero-dependency StatefulWidget using `Matrix4.rotationY` and `AnimationController` (300ms curve).
- **Trigger:** Added a dedicated `info_outline` icon to the top-right of the Front card. Tapping it triggers the flip. Tapping the top-right `close` icon on the Back returns to Front.

### B. Content Implementation
- **Front (`_buildPartnerProtocolFront`):** Preserved existing metrics/badges. Added Info trigger.
- **Back (`_buildPartnerProtocolBack`):**
  - **Educational Bullets:** Explained invite codes, 10-operator threshold, and terms.
  - **Mini Tier Strip:** Visual reinforcement of progress (+3 Levels).
  - **CTA:** Full-width "View Full Program Terms" button navigating to `PartnerTermsScreen`.
  - **Legal:** Added standard "Right to modify" footnote.

## 3. Verification
- **Compilation:** `flutter analyze` passed (clean, unused variable warnings addressed).
- **Runtime:** `flutter run -d chrome` verified smooth 3D flip animation.
- **Constraints:**
  - Reused `_buildPremiumCard` for both sides (pixel-perfect shell).
  - No new external dependencies.
  - Flip isolated to Partner Protocol card only.

## 4. Artifacts
- Proof: `outputs/proofs/polish/account_flip_01_partner_protocol_proof.json`

## 5. Next Steps
- Implement `PartnerTermsScreen` content (currently stub).
- Wire Invite Code generation to backend.
