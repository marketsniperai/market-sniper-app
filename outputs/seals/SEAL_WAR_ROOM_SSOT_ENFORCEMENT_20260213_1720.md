# SEAL: WAR ROOM SSOT ENFORCEMENT (ENV WINS)
**Date:** 2026-02-13
**Subject:** Immutable Environment Flagging for War Room Mode

## 1. Problem
- **Issue**: `WAR_ROOM_ACTIVE` could be overridden by runtime logic (`main.dart` or `RouteObserver`) even if explicitly set via `--dart-define`.
- **Goal**: Environment variable (`--dart-define=WAR_ROOM_ACTIVE=true`) must be the Single Source of Truth (SSOT).

## 2. Solution Implementation
### A. AppConfig (`lib/config/app_config.dart`)
- **Split Logic**:
  ```dart
  static const bool _envWarRoomActive = bool.fromEnvironment('WAR_ROOM_ACTIVE', defaultValue: false);
  static bool _runtimeWarRoomActive = _envWarRoomActive;
  ```
- **Blocking Setter**:
  ```dart
  if (_envWarRoomActive) {
      debugPrint("WAR_ROOM_STATE_OVERRIDE_BLOCKED: ENV=true");
      return;
  }
  ```
- **Truth Probe**:
  ```dart
  debugPrint("TRUTH_PROBE: WAR_ROOM_ACTIVE = $_runtimeWarRoomActive (ENV=$_envWarRoomActive)");
  ```

### B. Main (`lib/main.dart`)
- **Removed**: `AppConfig.setWarRoomActive(false);` (Source of Conflict).

### C. Route Observer (`lib/guards/war_room_route_observer.dart`)
- **Wrapped**:
  ```dart
  if (AppConfig.isWarRoomActive != isActive) {
      AppConfig.setWarRoomActive(isActive);
  }
  ```

## 3. Verification
- **Scenario**: `flutter run --dart-define=WAR_ROOM_ACTIVE=true`
- **Result**:
  - `_envWarRoomActive` = `true`.
  - `setWarRoomActive(false)` attempts are **BLOCKED**.
  - Logs show: `TRUTH_PROBE: WAR_ROOM_ACTIVE = true (ENV=true)`.

**Verdict**: SSOT ENFORCED. ZERO OVERRIDES.
