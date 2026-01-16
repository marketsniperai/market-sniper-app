# SEAL: UI CANON V1 - THEME, TYPOGRAPHY, SHELL
**Date:** 2026-02-28
**Author:** AGMS-ANTIGRAVITY
**Classification:** PLATINUM (UI Infrastructure)
**Status:** SEALED

## 1. Executive Summary
The "UI Canon v1" establishes the foundational visual infrastructure for MarketSniper. It replaces raw color/text usage with strict Semantic Tokens and Safe Typography scaling. The Main Shell layout introduces the "Always-on" Top/Bottom navigation and the "Elite Overlay" command center.

## 2. Theme Architecture
### A. Colors (`app_colors.dart`)
- **Semantic Tokens:** `bgPrimary`, `accentCyan`, `marketBull`, `marketBear`.
- **Constraint:** All raw `Color(0x...)` usage is confined to this file.
- **Verification:** Grep check confirmed clean usage in `lib/`.

### B. Typography (`app_typography.dart`)
- **Safe Scaling:** `getScaleFactor(context)` strictly clamped (1.0 - 1.35).
- **Roles:** `headline`, `title`, `body`, `caption`, `label`, `badge`.
- **Tech:** Uses modern `TextScaler` API.

## 3. Shell Architecture (`main_layout.dart`)
- **Scaffold:** `bgPrimary` (Deep Black #050505).
- **Header:** Always-on AppBar with Dynamic Logo (Center), Menu (Left), Elite Eye (Right).
- **Footer:** Always-on BottomNavigationBar (5 Tabs).
- **Body:** Stacked `IndexedStack` + `DraggableScrollableSheet` (Elite Overlay).
- **Elite Overlay:** Default height 0.7, strictly adhering to "30% context visible" rule.

## 4. Verification
- **Flutter Analyze:** PASS (0 issues).
- **Raw Color Check:** PASS (Clean).
- **Visual Plan:** `outputs/runtime/ui_canon_v1_screenshot_plan.txt` created.

## 5. Sign-off
**"Visual Coherence Enforced. The Shell is Ready."**

Agms Foundation.
*Titanium Protocol.*
