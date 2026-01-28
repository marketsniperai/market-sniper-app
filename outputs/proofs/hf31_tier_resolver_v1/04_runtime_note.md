# HF31 Runtime Note: 3-Tier Resolver & Gating

**Date:** 2026-01-28
**Context:** D47.HF31
**Status:** Verified

## 1. Resolver Logic (Source of Truth)
The `OnDemandTierResolver` unifies entitlements:
1.  **FOUNDER:** `AppConfig.isFounderBuild` -> **ELITE**.
2.  **ELITE:** `EliteAccessWindowController.resolve()` -> **ELITE** (if unlocked).
3.  **PLUS:** `PlusUnlockEngine.isUnlocked()` -> **PLUS**.
4.  **FREE:** Default.

## 2. Gating Rules Applied
| Widget | FREE | PLUS | ELITE |
| :--- | :--- | :--- | :--- |
| **Future Chart** | **BLURRED** | CLEAR | CLEAR |
| **Tactical Playbook** | **BLURRED** | CLEAR | CLEAR |
| **Mentor Bridge** | **LOCKED** | **LOCKED** | **UNLOCKED** |
| **Share Card** | **BLURRED** | **BLURRED** | **BLURRED** |

**Viral Safety:** The Share Mini-Card is fundamentally designed with blurred content to ensure no premium intel leaks via viral channels. This is enforced at the widget level (`MiniCardWidget`).

## 3. Verified Scenarios
- **Free:** Default state verified. Blur overlays active.
- **Plus:** Simulated via `PlusUnlockEngine` mock. Future/Tactical clear, Mentor remaining locked.
- **Elite:** Simulated via Founder mode. All Clear.
