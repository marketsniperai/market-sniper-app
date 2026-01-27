# SEAL_DAY_XX_WELCOME_02_INVITE_GATE_ATTRIBUTION

**Status**: SEALED
**Time**: 2026-01-23
**Logic**: Local Deterministic + Ledger

## Summary
Implemented a secure, local-first Invitation Code gate for the `WelcomeScreen`. The system uses `InviteService` for persistence and ledgering, ensuring zero reliance on external networks for core access.

## Changes
- **New Service**: `InviteService` (Logic, Ledger, State).
- **New Widget**: `InviteLogicTile` (War Room visibility).
- **Config**: `AppConfig` updated with `inviteEnabled`, `invitePattern` (`^MS-[A-Z0-9]{5}$`), and Founder Bypass.
- **Frontend**: `WelcomeScreen` wired to validate code before `_enterSystem`.
- **UI**: Premium inline error text (Soft Red `0xFFFF6B6B`) added. No layout shifts.

## Persistence
- **State/Ledger**: `SharedPreferences` (Keys: `invite_code`, `invite_ledger_list`).
- **Compatibility**: Universal (Mobile + Web + Desktop). No `dart:io` dependencies.

## Verification
- **Gate**: Blocks `_enterSystem` if invite is invalid.
- **Bypass**: Founder build allows bypass if configured.
- **Ledger**: Events recorded for SUBMIT (Valid/Invalid).
- **Display**: War Room shows tail of ledger events.
