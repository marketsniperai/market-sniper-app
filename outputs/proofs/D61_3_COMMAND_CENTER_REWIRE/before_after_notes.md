# D61.3 Command Center Rewire Notes

## Before
- **Command Center Screen**: Used local `PremiumStatusResolver` logic with ad-hoc "Restricted Surface" full-screen blur. No `CoherenceQuartet`.
- **War Room Screen**: Had `CoherenceQuartetCard` injected into the body list, hijacking the Founder view.
- **Enums**: `CommandCenterTier` was duplicated in 2 files.

## After
- **Command Center Screen**:
    - Imports `DisciplineCounterService` and `CoherenceQuartetCard`.
    - Uses `command_center_tier.dart` (Canonical).
    - `CoherenceQuartetCard` is the Top Anchor.
    - Content below Quartet is strictly gated (`canShowDeepContent`).
    - Legacy overlays removed; Quartet handles self-gating.
- **War Room Screen**:
    - `CoherenceQuartetCard` removed from body.
    - Founder Ops Grid restored to purity.
    - `GlobalCommandBar` remains for Founder status visibility.
- **Enums**: Single source of truth.

## Logic
- **Plus**: Partial visibility in Quartet, Content below is visible (since they are "inside").
- **Free**: Frosted Quartet (Upsell), Content below is HIDDEN.
