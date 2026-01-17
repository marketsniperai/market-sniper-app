# SEAL: D37.03 - LIVE/STALE/LOCKED PRECEDENCE

**Date:** 2026-01-16
**Author:** Antigravity (AI Agent)
**Objective:** Enforce canonical precedence (LOCKED > STALE > LIVE) for system data state.

## 1. Changes Implemented
- **Logic (`data_state_resolver.dart`):**
  - Created central resolver.
  - Precedence: 
    1. **LOCKED**: Misfire, Failsafe (Health), or Watchdog Lockdown (SSOT).
    2. **STALE**: Age > 300s.
    3. **LIVE**: Age <= 300s.
- **UI (`session_window_strip.dart`):** Updated to display LOCKED state (Neon Red).
- **Wiring (`dashboard_screen.dart`):** Integrated resolver; updated Founder Debug to show reason codes.

## 2. Governance Compliance
- **SSOT Wiring:** Consumes `dashboard_market_sniper.json` and `SystemHealth`.
- **Thresholds:** 300s default stale threshold (canonical).
- **Verification:**
  - `flutter analyze`: **PASS**.
  - `flutter build web`: **PASS**.
  - `verify_project_discipline.py`: **PASS**.

## 3. Verification Result
The system correctly resolves states. LOCKED signals override freshness. Stale age triggers STALE state.

## 4. Final Declaration
I certify that the Data State Constitution is active and binding.

**SEALED BY:** ANTIGRAVITY
**TIMESTAMP:** 2026-01-16 T14:52:00 EST
