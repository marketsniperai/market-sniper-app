# SEAL: DAY 45.12 — SHARE ATTRIBUTION DASHBOARD
> [!NOTE]
> **SUPERSEDED IN PART**: The "Access Control: Restricted to Founder builds via the Main Drawer" section is obsolete. The Drawer has been replaced by `MenuScreen` in `SEAL_Polish_Menu_01_Fullscreen_Menu_NoDrawer.md`.


## SUMMARY
D45.12 introduces the **Founder-only Share Attribution Dashboard** ("Growth Bloomberg"). It aggregates telemetry from the Share Engine to visualize Key Performance Indicators (e.g., Shares/24h, Click Rate/7d) and volume trends. It operates in strict read-only mode using a local ledger aggregation strategy.

## FEATURES
- **Aggregator**: `ShareAttributionAggregator` parses local telemetry logs.
- **Dashboard UI**: `ShareAttributionDashboardScreen` displays KPIs, Daily Volume tables, and Surface breakdown.
- **Access Control**: Restricted to Founder builds via the Main Drawer.
- **Policy**: `outputs/os/os_share_attribution_dashboard_policy.json` defines metrics and bounds.

## ARTIFACTS
- `market_sniper_app/lib/logic/share/share_attribution_aggregator.dart` (New)
- `market_sniper_app/lib/screens/share_attribution_dashboard_screen.dart` (New)
- `market_sniper_app/lib/layout/main_layout.dart` (Modified)
- `outputs/os/os_share_attribution_dashboard_policy.json` (New)

## PROOF
- `outputs/proofs/day_45/ui_share_attribution_dashboard_proof.json`

## STATUS
**SEALED**
