# SEAL: MENU SHELL MATERIAL ANCESTOR HOTFIX (HOTFIX.MENU.SHELL.02)
> **ID:** SEAL_HOTFIX_MENU_SHELL_02_MATERIAL_ANCESTOR
> **Date:** 2026-01-24
> **Author:** Antigravity (Agent)
> **Status:** SEALED

## 1. Issue
When embedding `MenuScreen` into `MainLayout` (removing `Scaffold`), internal widgets like `Switch` and `InkWell` lost their required `Material` ancestor, potentially causing runtime errors or visual glitches (e.g., missing ripple effects).

## 2. Resolution
Wrapped the conditional `MenuScreen` rendering in `MainLayout` with a `Material` widget:
```dart
Material(
  type: MaterialType.transparency, // Preserves background color/opacity
  child: MenuScreen(...),
)
```

## 3. Verification
- **Structure:** Confirmed `Material` is the direct parent of `MenuScreen` in the widget tree.
- **Visuals:** `MaterialType.transparency` ensures no unwanted background or elevation is added.
- **Functionality:** Switches and touch targets operate correctly within the shell.

## 4. Conclusion
The Menu System is now both Global Shell compliant AND runtime stable.
