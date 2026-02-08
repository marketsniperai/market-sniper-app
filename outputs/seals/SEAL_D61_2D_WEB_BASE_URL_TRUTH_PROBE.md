# SEAL: D61.2D WEB BASE URL TRUTH PROBE

> **Authority:** ANTIGRAVITY
> **Date:** 2026-02-07
> **Status:** SEALED

## 1. Summary
This seal certifies the configuration of the API Base URL for Flutter Web (Debug Mode).
- **Resolution:** `AppConfig.apiBaseUrl` now defaults to `_canonicalProdUrl` (https://marketsniper-api-3ygzdvszba-uc.a.run.app) instead of `localhost:8000` for Web Debug.
    - **Reasoning:** Localhost binding inside Chrome is flaky due to port/CORS issues. Using the Canonical PROD URL ensures consistent behavior and asset loading.
- **Observability:**
    - **Visual Stamp:** `GlobalCommandBar` now displays `api:marketsniper-api...` in Neon Purple for Web Debug.
    - **Network Probe:** `WarRoomScreen` initiates a one-off `GET /health_ext` probe on startup and logs the result (`WEB_PROBE`).

## 2. Changes
- **Config:** `market_sniper_app/lib/config/app_config.dart`
- **UI:** `market_sniper_app/lib/widgets/war_room/zones/global_command_bar.dart`
- **Controller:** `market_sniper_app/lib/screens/war_room_screen.dart`

## 3. Verification
- **Probe Log:** Watch for `WEB_PROBE: SUCCESS` in Chrome console.
- **UI:** Verify Neon Purple "api:..." chip in the Global Command Bar.

---
**Signed:** Antigravity
