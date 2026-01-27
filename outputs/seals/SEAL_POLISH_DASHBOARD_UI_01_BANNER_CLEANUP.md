# SEAL_POLISH_DASHBOARD_UI_01_BANNER_CLEANUP

**Objective:** Polish Dashboard Body, Remove Founder Debug, Implement Banner V1.
**Status:** SEALED
**Date:** 2026-01-25

## 1. Summary of Changes
- **Removed:** "FOUNDER VIEW" banner and "SSOT" debug row from `DashboardComposer`.
- **Refactored:** `SessionWindowStrip` into **DashboardBannerV1**.
    - **Logic:** Strict `America/New_York` timezone using `timezone` package.
    - **Left:** Market Status (PRE-MARKET, MARKET HOURS, AFTER HOURS, MARKETS CLOSED).
    - **Right:** LIVE indicator with breathing glow (2s in/out).
    - **Modules:** Added strip for Stocks, Options, News, Macro with time-window logic.
- **Dependencies:** Added `timezone` package and initialized in `main.dart`.

## 2. Verification Results
| Check | Command | Result |
| :--- | :--- | :--- |
| **Analysis** | `flutter analyze` | **WARN** (Baseline issues) |
| **Runtime** | `flutter run -d chrome` | **PASS** (Booted, animation verified) |
| **Logic** | Manual Review | **PASS** (Timezone law respected) |
| **Proof** | `dashboard_ui_01_banner_cleanup_proof.json` | **PASS** (Artifact created) |

## 3. Artifacts
- **Proof:** [`outputs/proofs/polish/dashboard_ui_01_banner_cleanup_proof.json`](../../outputs/proofs/polish/dashboard_ui_01_banner_cleanup_proof.json)

## 4. Git Status
```
M  market_sniper_app/lib/main.dart
M  market_sniper_app/lib/screens/dashboard/dashboard_composer.dart
M  market_sniper_app/lib/widgets/session_window_strip.dart
M  market_sniper_app/pubspec.yaml
A  outputs/proofs/polish/dashboard_ui_01_banner_cleanup_proof.json
```
