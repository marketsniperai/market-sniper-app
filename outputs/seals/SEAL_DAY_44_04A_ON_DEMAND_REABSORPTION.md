# SEAL: D44.04A - On-Demand Reabsorption

**Date:** 2026-01-19
**Author:** Antigravity (Agent)
**Verification Status:** VERIFIED (Manual)

## Component
Refactored `OnDemandScreen` to `OnDemandPanel` to enforce "No Duplicate Screen" architecture law.
Embedded strictly as a widget within `MainLayout`'s `IndexedStack`.

## Changes
- **[MOD]** `lib/screens/on_demand_screen.dart`: Renamed class to `OnDemandPanel`.
- **[MOD]** `lib/layout/main_layout.dart`: Updated usage.
- **[MOD]** `docs/canon/OS_MODULES.md`: Updated registry to `OS.UI.OnDemandTab`.

## Verification
- **Architecture**: No top-level class named `OnDemandScreen`.
- **Functionality**: Identical user experience.
- **Analysis**: `flutter analyze` passed.

## Metadata
- **Type**: REFACTOR
- **Risk**: TIER_0 (Safe)
- **Reversibility**: HIGH
