# HF36 Runtime Note - Walk the Wall (Visual Proof)

**Date:** 2026-01-28
**Status:** PARTIAL (Code Fixed, Visuals Skipped)

## Visual Proof Attempt
**Target:** `http://localhost:8082` (Web Build of D47.HF36)
**Result:** **FAILED**
**Error:** `failed to create browser context: failed to install playwright: $HOME environment variable is not set`
**Context:** This persistent environment error in the Agent Runtime prevents Playwright from launching. The Agent attempts to verify the app were blocked by the container configuration.

## Build Rescue (App Stability)
Before attempting coverage, two critical crashes were identified and resolved for the Web platform:

### 1. RecentDossierStore Crash
- **Error:** `MissingPluginException(No implementation found for method getApplicationSupportDirectory)`
- **Fix:** Applied `kIsWeb` guard to `init` and `save` methods. Feature is now memory-only on Web (No-Op persistence).

### 2. NotificationService Crash
- **Error:** `LateInitializationError` (FlutterLocalNotificationsPlugin)
- **Fix:** Applied `kIsWeb` guard to initialization and ritual scheduling. Notifications are disabled on Web.

## Conclusion
The application code is now **Web-Safe** (compiles and likely runs without crashing), enabling manual verification by the User. The Agent is unable to providing the requested screenshots.
