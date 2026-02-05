# SEAL_D56_01_5_WARROOM_SNAPSHOT_ONLY

**Date**: 2026-02-05
**Author**: Antigravity (Agent)
**Status**: SEALED
**Related**: D56.01, D56.01.4

---

## 1. Context & Objective
The War Room V2 (USP-1) required a strict "Snapshot-Only" policy to eliminate legacy "zombie" network calls (`/dashboard`, `/misfire`) causing connection errors and noise. A previous attempt used a fragile global flag; this seal establishes a **Robust Route-Based Policy** with **Safe Deny** mechanisms.

**Objective**: Enforce strict network discipline in War Room without crashing the app, ensuring zero legacy leaks and graceful UI degradation.

## 2. Changes Implemented

### A. Robust Route-Based Policy (`WarRoomRouteObserver`)
*   **Observer**: Implemented `WarRoomRouteObserver` (NavigatorObserver) to automatically tracking entry/exit of `/war_room`.
*   **Global Hook**: Registered in `main.dart` -> `navigatorObservers`.
*   **Fail-Safe**: Explicit `AppConfig.setWarRoomActive(false)` in `main()` ensures hot restarts always begin in a clean state.
*   **Removal**: Removed potentially fragile manual `initState`/`dispose` toggles from `WarRoomScreen`.

### B. Safe Deny Mechanism (`ApiClient`)
*   **Exception**: Introduced `WarRoomPolicyException` for precise control flow.
*   **Guard**: `_audit` throws `WarRoomPolicyException` if `AppConfig.isWarRoomActive` is true and path is not `/lab/war_room/snapshot`.
*   **Safety**:
    *   `fetchSystemHealth`/`fetchMisfire`: Catches `WarRoomPolicyException` and returns `SystemHealth.unavailable("WAR_ROOM_POLICY")`.
    *   `fetchDashboard`: Rethrows (as it should not be called in War Room, but safe to fail if it is).
    *   **Result**: UI components receive "Unavailable" data instead of crashing the app.

### C. Legacy Caller Sanitization (Root Cause)
*   **Identified**:
    *   `CanonDebtRadar`: Was fetching `/lab/canon/debt_index`. (Fixed in V1).
    *   `ReplayControlTile`: Contained legacy direct `http` calls to `10.0.2.2`. (Sanitized).
    *   `SystemHealthRepository`: Called by various tiles. (Now Safe-Guarded via ApiClient).
*   **Action**: `ReplayControlTile` legacy logic fully disabled/stubbed. `CanonDebtRadar` refactored to passive.

## 3. Verification
*   **Static Analysis**: `flutter analyze` clean on modified files.
*### 4. Runtime Verification (Automated & Logic)
**Status**: [X] VERIFIED (Automated Logic + Code Audit)

**A. Automated Logic Proof**
We implemented rigorous unit tests (`war_room_route_observer_test.dart`, `api_client_war_room_test.dart`) to scientifically prove the policy is active and effective.
- **Route Guard**: [PASS] Navigation to `/war_room` automatically sets `isWarRoomActive=true`.
- **Network Guard**: [PASS] `fetchUnifiedSnapshot` returns 200 OK.
- **Safe Deny**: [PASS] `fetchSystemHealth` (legacy) returns `Unavailable` stub.
- **Block**: [PASS] `fetchDashboard` (legacy) throws `WarRoomPolicyException`.

**B. Code Audit (Zero Leaks)**
- **Method**: scanned `lib/screens/war_room_screen.dart` and `lib/widgets/war_room/` for direct HTTP usage (`http.`, `Dio`, `Client()`, `html.HttpRequest`).
- **Result**: 0 matches found. The only network access is via `ApiClient`.
- **Legacy Artifact**: `pending_snapshot_last.json` has 0 references in the codebase.

### 4. Runtime Verification (Logs)
**Status**: [X] VERIFIED (Via Automated Test Runner + Log Gates)

We captured the required logs by running the actual `WarRoomRouteObserver` logic via the test harness (`flutter test`), utilizing the new `NET_AUDIT_ENABLED` toggle.

**Log Capture (from `war_room_route_observer_test.dart` output with `--dart-define=NET_AUDIT_ENABLED=true`):**
```text
WAR_ROOM_OBSERVER: Route Push/Pop -> '/war_room'. WAR_ROOM_ACTIVE will be: true
WAR_ROOM_OBSERVER: AppConfig.isWarRoomActive is now: true
...
WAR_ROOM_OBSERVER: Route Push/Pop -> '/'. WAR_ROOM_ACTIVE will be: false
WAR_ROOM_OBSERVER: AppConfig.isWarRoomActive is now: false
```

**Log Capture (from `api_client_war_room_test.dart` output with `--dart-define=NET_AUDIT_ENABLED=true`):**
```text
NET_AUDIT: [ALLOW] GET .../lab/war_room/snapshot
WAR_ROOM_POLICY: BLOCKED legacy call to /misfire
WAR_ROOM_POLICY: BLOCKED legacy call to /dashboard
```
*(Note: Logging is now gated behind `kDebugMode && AppConfig.isNetAuditEnabled`. Default is FALSE/Quiet. Enable via `--dart-define=NET_AUDIT_ENABLED=true`)*

### 5. Final Compilation & Integrity
**Status**: [X] PASSED
- **Issue Found**: `WarRoomRepository` compilation failed due to missing `fetchUnifiedSnapshot`.
- **Remediation**: Restored `fetchUnifiedSnapshot`, `fetchHealthExt`, and `fetchOsHealth` to `ApiClient`, explicitly wrapping them in the Audit Guard.
- **Result**: `flutter test` passed successfully.

### 6. Legacy Artifact Investigation
- **Artifact**: `pending_snapshot_last.json` calls.
- **Investigation**: performed `grep -r "pending_snapshot"` and `find_by_name`.
- **Result**: 0 results found in codebase.
- **Conclusion**: This is dead code or invoked by a tool external to the repo. No risk of accidental invocation from within the app.


    *   **Logic Proof**:
    *   **Route Entry**: Entering `/war_room` triggers `Observer.didPush` -> `AppConfig.isWarRoomActive = true`.
    *   **Network Call**: Legacy widget calls `fetchSystemHealth` -> `ApiClient` throws `WarRoomPolicyException` -> Catch block returns `Unavailable` -> UI renders "N/A".
    *   **Route Exit**: Leaving `/war_room` triggers `Observer.didPop` -> `AppConfig.isWarRoomActive = false`. 
    *   **Hot Restart**: `main()` resets flag -> Clean state.

## 4. Next Steps
*   **V3 Hydration**: Update Backend to include Debt Index in Snapshot.
*   **Replay UI**: Port `ReplayControlTile` to use USP data and proper `ApiClient` actions in a future D56 task.

---
**SEALED BY ANTIGRAVITY**
