# Runtime Note: D48.BRAIN.03 — Surface Adapters V1

## Architectural Shift
Moved complex `Map<String, dynamic>` parsing OUT of `OnDemandPanel.build()` and into `OnDemandAdapter`.
Each widget now consumes strong ViewModels:
- `TimeTravellerChart` -> `TimeTravellerModel`
- `ReliabilityMeter` -> `ReliabilityModel`
- `IntelCards` -> `IntelDeckModel`
- `TacticalPlaybook` -> `TacticalModel`

## Safety Benefits
- **Null Safety**: Adapter handles missing keys gracefully (e.g. `_safeStringList`).
- **Type Safety**: Enums for states (e.g. `AdapterReliabilityState`) instead of raw Strings.
- **Testability**: `adapter_smoke_test.dart` verifies logic in isolation without spinning up Flutter UI.

## Mapping Decisions
- **Sentiment**: Mapped logic from "win_rate > 0.6" to `AdapterSentiment.bullish`, decoupling UI colors from data.
- **Calibrating States**: Explicitly handled in VM creation.

## UI Impact
- **Zero Visual Change**: The UI renders identical pixel-perfect output.
- **Performance**: Negligible overhead (parsing is O(1) for small JSONs). Passing reference models is cheap.
