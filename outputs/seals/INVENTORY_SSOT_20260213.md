# INVENTORY: FRONTEND SSOT & LEGACY CALLS
**Date:** 2026-02-13
**Scope:** `market_sniper_app/lib/services/api_client.dart`

## 1. Classification Matrix

| Method | Path | Status | Policy |
| :--- | :--- | :--- | :--- |
| **fetchUnifiedSnapshot** | `/lab/war_room/snapshot` | **SSOT** | **PRIMARY** (Allowed Everywhere) |
| `postWatchlistLog` | `/lab/watchlist/log` | **Non-SSOT** | **ALLOWED** (Write/Telemetry) |
| `fetchDashboard` | `/dashboard` | Legacy | **FORBIDDEN** in War Room |
| `fetchWarRoomDashboard` | `/lab/war_room` | Legacy | **FORBIDDEN** in War Room |
| `fetchSystemHealth` | `/system_health` | Legacy | **FORBIDDEN** in War Room |
| `fetchAutofixStatus` | `/lab/autofix/status` | Legacy | **FORBIDDEN** in War Room |
| `fetchIronStatus` | `/lab/os/iron/status` | Legacy | **FORBIDDEN** in War Room |
| `fetchMisfireStatus` | `/misfire` | Legacy | **FORBIDDEN** in War Room |
| `fetchHousekeeperStatus` | `/lab/os/self_heal/housekeeper/status` | Legacy | **FORBIDDEN** in War Room |
| `fetchUniverse` | `/universe` | Legacy | **FORBIDDEN** in War Room |
| `fetchLiveOverlay` | `/overlay_live` | Feature | **FORBIDDEN** in War Room (Context dependent) |
| `fetchOnDemandContext` | `/on_demand/context` | Feature | **FORBIDDEN** in War Room (Use Snapshot) |
| `fetchNewsDigest` | `/news` | Feature | **FORBIDDEN** in War Room |
| `fetchEconomicCalendar` | `/macro/calendar` | Feature | **FORBIDDEN** in War Room |
| `fetchOptionsContext` | `/options` | Feature | **FORBIDDEN** in War Room |
| *All Checkers/Probes*| *Various* | Legacy | **FORBIDDEN** in War Room |

## 2. War Room Policy
**Rule:** When `AppConfig.isWarRoomActive` is `true`:
1.  **ALLOW**: `/lab/war_room/snapshot` (Unified Snapshot)
2.  **ALLOW**: `/lab/watchlist/log` (Telemetry/Writes)
3.  **DENY**: Everything else -> `WarRoomPolicyException`

## 3. Rewire Status
- **War Room**: Migrated to `WarRoomSnapshot`. Widgets (AlphaStrip, Honeycomb, etc.) consume props.
- **Direct Http**: Found in `WarRoomScreen._runProbes` (Debug Only) - **EXEMPT** (Bypasses ApiClient).
