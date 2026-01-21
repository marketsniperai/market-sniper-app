# SEAL: DAY 45.18 — PROVIDER STATUS INDICATOR

## SUMMARY
D45.18 implements the **Provider Status Indicator**, a lightweight institutional dot+label inside the System Status Panel. It visualizes the health of upstream data sources (Polygon, Macro Feeds). Logic adheres to "Any DOWN → DEGRADED" rule. Founders can tap to inspect the specific breakdown (e.g., Polygon: UP, Fred: DOWN).

## FEATURES
- **Indicator**: Dot + Label (LIVE/DEGRADED/DOWN).
- **Logic**: Derived from `SystemHealthSnapshot.providers` map parsed from `/health_ext`.
- **Founder Mode**: Interactive breakdown modal.
- **Location**: Right-aligned in System Status Panel, complementary to Data State.

## ARTIFACTS
- `market_sniper_app/lib/widgets/provider_status_indicator.dart` (New)
- `market_sniper_app/lib/widgets/session_window_strip.dart` (Modified)
- `market_sniper_app/lib/models/system_health_snapshot.dart` (Modified)
- `market_sniper_app/lib/repositories/system_health_repository.dart` (Modified)
- `market_sniper_app/lib/screens/dashboard/dashboard_composer.dart` (Modified)

## PROOF
- `outputs/proofs/day_45/ui_provider_status_indicator_proof.json`

## STATUS
**SEALED**
