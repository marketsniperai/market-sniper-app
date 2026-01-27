# SEAL: VISUAL POLISH: NEON CYAN UNIFICATION

**Task:** D45.POLISH.01 — Visual Polish: Neon Cyan Unification
**Status:** SEALED (PASS)
**Authority:** ANTIGRAVITY
**Time:** 2026-02-18

## 1. Rationale
To ensure premium visual coherence and strictly enforced color discipline, we have unified all accent cyan tokens to a canonical `AppColors.neonCyan` (0xFF00F5FF) and introduced a reusable `NeonOutlineCard` component. We also remediated widespread hardcoded color violations in `AccountScreen`, `WelcomeScreen`, and others to pass the discipline verifier.

## 2. Manifest of Changes

### A. Canonization
- **New Token:** `AppColors.neonCyan` (0xFF00F5FF) — The single source of truth for "Sniper Cyan".
- **New Token:** `AppColors.neonCyanOutline` (0x6600F5FF) — For 1px borders (40% opacity).
- **Legacy Match:** `AppColors.accentCyan` aliased to `neonCyan` to prevent regressions while enforcing the new value.

### B. Components
- **[NEW] NeonOutlineCard:** (`lib/widgets/atoms/neon_outline_card.dart`)
  - Standardizes the "thin neon border" look.
  - Consistent border radius (12px).
  - Configurable background (default surface or transparent).

### C. Surfaces Polished
- **War Room Tiles:** Updated `WarRoomTileWrapper` to use `NeonOutlineCard`.
- **Menu Screen:** Updated toggle items and menu rows to use `NeonOutlineCard` (transparent bg, neon outline).
- **Options Intelligence:** Updated `OptionsContextWidget` to use `NeonOutlineCard` (replacing `GlassCard` usage).
- **Welcome Screen:** Normalized `_neonCyan` and removed/replaced hardcoded color literals.

### D. Discipline Remediation (Verifier Compliance)
- **AccountScreen:** Replaced `Colors.white`, `whiteXX`, `Colors.black`, `Colors.blue`, `Colors.amber` with semantic `AppColors` tokens (`textPrimary`, `bgDeepVoid`, `stateStale`, etc.).
- **StartupGuard:** Replaced `Colors.black` scaffold with `AppColors.bgPrimary`.
- **InviteLogicTile:** Replaced `Colors.greenAccent` with `AppColors.stateLive` and removed color comments.
- **RitualPreviewScreen:** Replaced `Colors.white`/`Colors.black` with `textPrimary`/`bgDeepVoid`.

## 3. Verification
- **Discipline Check:** `verify_project_discipline.py` passed (exit code 0 after fixes).
- **Compilation:** `flutter analyze` passed (with pre-existing warnings unrelated to this change).
- **Git Hygiene:** All new files tracked and staged.

## 4. Artifacts
- Proof: `outputs/proofs/polish/visual_cyan_unification_proof.json`
- Component: `market_sniper_app/lib/widgets/atoms/neon_outline_card.dart`

## 5. Next Steps
- Continue applying `NeonOutlineCard` to future "boxed" UI elements.
- Maintain discipline on new screens to avoid "Colors.white" regression.
