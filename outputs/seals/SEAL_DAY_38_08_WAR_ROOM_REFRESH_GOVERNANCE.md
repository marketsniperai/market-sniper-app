# SEAL: D38.08 - War Room Refresh & Consistency Governance
**Date:** 2026-01-16
**Author:** Antigravity (Agent)
**Authority:** D37.07 (Dashboard Governance)
**Strictness:** HIGH

## 1. Summary
This seal certifies the implementation of the **War Room Refresh Governance**, preventing excessive polling and ensuring atomic, consistent updates across all tiles.

## 2. Policy
- **Auto-Refresh:** Every **60 seconds** (default).
- **Manual Cooldown:** **15 seconds**.
- **Backoff:** **120 seconds** if System is `LOCKED` or any tile is `UNAVAILABLE`.
- **Lifecycle:** Pauses when app is backgrounded.
- **Feedback:** "Refreshing..." indicator visible ONLY in Founder builds.

## 3. Implementation
- **Controller:** `WarRoomRefreshController` (new) manages timer and state.
- **Integration:** `WarRoomScreen` binds lifecycle observer and delegates refresh logic.
- **Atomicity:** `WarRoomRepository` fetches all snapshot components in parallel, delivering a single unified state update to prevent UI tearing.

## 4. Verification
- **Discipline:** `verify_project_discipline.py` PASSED.
- **Analysis:** `flutter analyze` PASSED.
- **Build:** `flutter build web` PASSED.
