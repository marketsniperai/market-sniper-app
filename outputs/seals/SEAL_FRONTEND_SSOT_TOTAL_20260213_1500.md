# SEAL: FRONTEND SSOT TOTAL — UNIFIED SNAPSHOT POLICY
**Date:** 2026-02-13
**Author:** Antigravity

## 1. Objective
Enforce strict "Snapshot-Only" data consumption within the War Room (`WarRoomActive`), ensuring total alignment with the Unified Snapshot Protocol (USP-1).

## 2. Changes
- **Inventory Audit**: Classified all `ApiClient` methods (`INVENTORY_SSOT_20260213.md`).
- **Policy Enforcement**: Updated `ApiClient.dart` to throw `WarRoomPolicyException` for any non-snapshot calls when War Room is active.
    - **Allowed**: `/lab/war_room/snapshot` (Read SSOT), `/lab/watchlist/log` (Write Telemetry).
    - **Blocked**: All legacy endpoints (`/dashboard`, `/system_health`, etc.).
- **Rewire Verification**: Confirmed War Room widgets (`AlphaStrip`, `ServiceHoneycomb`, `GlobalCommandBar`) consume props from `WarRoomSnapshot` only.
- **Syntax Fix**: Resolved a critical bracket mismatch in `command_center_screen.dart` that blocked compilation.

## 3. Verification Evidence

### A. Build Integrity (`flutter build web --release`)
```text
Compiling lib\main.dart for the Web...                             28.5s
√ Built build\web
Exit code: 0
```

### B. Policy Enforcement Test (`flutter test`)
**File:** `test/verify_ssot_enforcement_test.dart`
```text
TEST: War Room Active = true
TEST: Verifying fetchDashboard is BLOCKED... (PASSED)
TEST: Verifying fetchUnifiedSnapshot is ALLOWED... (PASSED)
TEST: Verifying postWatchlistLog is ALLOWED... (PASSED)
TEST: Deactivating War Room...
TEST: Verifying fetchDashboard is ALLOWED (Inactive)... (PASSED)
TEST: SSOT Enforcement VERIFIED.
```

### C. Grep Proof (Zero Unauthorized Calls in War Room Widgets)
**Command:** `findstr /S /I "fetchDashboard fetchSystemHealth fetchAutofixStatus fetchUniverse" market_sniper_app\lib\widgets\war_room\*.dart`
**Result:** `Exit code 1` (0 matches found).

## 4. Verdict
**NOMINAL**. The Frontend now strictly adheres to the Unified Snapshot Protocol within the War Room. Legacy calls are physically blocked, preventing regression.

**Sign-off**: Antigravity
