# SEAL: POLISH.SHELL.GLOBAL.01 — Global Shell Persistence

> [!IMPORTANT]
> This seal certifies the enforcement of the "One Shell" architecture.

## 1. Context
To maintain a "Premium Institutional" feel, the application must never lose the Top Bar branding or the Bottom Navigation context. Previous implementations of the Menu or other screens occasionally used full-screen routes (`Navigator.push`), breaking this continuity.

## 2. Architecture Enforced
- **Single Root Scaffold:** `MainLayout` is the authority.
- **IndexedStack Strategy:** All core tabs live in a preserved state stack.
    1. Home (Dashboard)
    2. Watchlist
    3. News
    4. On-Demand
    5. Calendar
- **Menu Overlay:** The Menu is now an *embedded panel* inside the shell's body, toggled via state (`_isMenuOpen`), rather than a pushed route.
- **Geometry:** Top Bar and Bottom Nav are **pinned** ancestors to the dynamic body content.

## 3. Verification
- **Structural:** Code review confirmed `Scaffold` hierarchy in `main_layout.dart`.
- **Runtime:** Verified logic ensures `MenuScreen` replaces `IndexedStack` visually but keeps the shell frame intact.
- **Safety:** Hotfixes 02/03 (Material Ancestor) ensure this embedded structure is stable.

## 4. Manifest
- `lib/layout/main_layout.dart` (Validated)
- `outputs/proofs/polish/global_shell_persistence_proof.json` (Proof)

## 5. Next Steps
- Verify "Founders Key" persistent storage.
- Verify "Terms of Use" mode.

> **Signed:** Antigravity
> **Timestamp:** 2026-01-23T18:55:00Z
