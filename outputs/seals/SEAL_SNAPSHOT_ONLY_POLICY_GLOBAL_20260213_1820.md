# SEAL: SNAPSHOT ONLY POLICY GLOBAL
**Date:** 2026-02-13
**Subject:** Global Switch to Enforce SSOT

## 1. Policy Definition
- **Flag**: `AppConfig.isSnapshotOnlyMode`
- **Logic**: `isWarRoomActive || SNAPSHOT_ONLY=true`
- **Effect**: All legacy direct API calls throw `WarRoomPolicyException`.

## 2. Implementation
- **AppConfig**: Added `isSnapshotOnlyMode` getter.
- **ApiClient**: 
  - Added `_checkSnapshotPolicy(endpoint)`.
  - Applied check to all legacy `fetch*` methods.
  - Added `fetchUnifiedSnapshotRaw` (Whitelisted).

## 3. Coverage
| Method | Policy |
| :--- | :--- |
| `fetchDashboard` | **BLOCKED** |
| `fetchMisfireStatus` | **BLOCKED** |
| `fetchSystemHealth` | **BLOCKED** |
| `fetchUniverse` | **BLOCKED** |
| `fetchNews` | **BLOCKED** |
| `fetchUnifiedSnapshotRaw` | **ALLOWED** |
| `postWatchlistLog` | **ALLOWED** (Write) |

**Verdict**: POLICY WIRED. LEGACY PATHS CLOSED IN WAR ROOM.
