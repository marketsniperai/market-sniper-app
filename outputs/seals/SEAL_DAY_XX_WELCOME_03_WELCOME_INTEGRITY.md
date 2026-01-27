# SEAL_DAY_XX_WELCOME_03_WELCOME_INTEGRITY

**Status**: SEALED
**Time**: 2026-01-23
**Focus**: Route Guard, Normalization, Terms Hashing

## Summary
Finalized the integrity of the Welcome Screen and Startup flow. Implemented a `StartupGuard` to protect the main shell, enforced normalization on invite codes, and added terms content hashing for precise version tracking.

## Changes
- **Guard**: `StartupGuard` wraps `/startup` -> Redirects to `/welcome` if invalid.
- **Service**: `InviteService` adds `normalize()` (Upper+Trim) and `recordTermsAcceptance(hash)`.
- **UI**: `WelcomeScreen` normalizes inputs on submit and stamps terms acceptance with a DJB2-style hash.
- **Config**: `main.dart` initializes `InviteService` globally.

## Integrity Measures
1.  **Route Protection**: Direct navigation to `/startup` is blocked without valid invite/bypass.
2.  **Input Hygiene**: " ms-abc " -> "MS-ABC".
3.  **Terms Stamp**: `terms_hash` stored in SharedPreferences and Ledger.
4.  **Web Compatible**: Zero `dart:io` deps in critical path.

## Verification
- **Manual**: Normalized inputs act as expected.
- **Route**: `StartupGuard` active in `main.dart`.
- **Ledger**: Records `invite_normalized` and `HASH:...`.
