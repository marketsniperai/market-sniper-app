# SEAL: D44.02B - Watchlist Analyze Now Flow

**Date:** 2026-01-19
**Author:** Antigravity (Agent)
**Verification Status:** VERIFIED (Automated)

## Logic Implemented
1. **LOCKED/STALE State**:
   - Detects `DEGRADED`, `MISFIRE`, or `LOCKED` status from `SystemHealthRepository`.
   - Fetches lightweight `LockReasonSnapshot` (via new `WarRoomRepository.fetchLockReason()`).
   - Displays canonical `LockReasonModal` (D44.02A).
   - Logs "BLOCKED" action to local `watchlist_actions_ledger.jsonl`.

2. **LIVE State**:
   - Detects `NOMINAL` or `LIVE` status.
   - Navigates to **On-Demand Panel** (Index 3) using `NavigationBus`.
   - Prefills ticker and auto-triggers analysis.
   - Logs "OPENED_RESULT" action to local `watchlist_actions_ledger.jsonl`.

## Architecture
- **NavigationBus**: Decouples `WatchlistScreen` from `MainLayout`.
- **WatchlistLedger**: Isolated logging logic.

## Layout Compliance
- `WatchlistScreen` maintains `ListView` with bottom padding.
- `OnDemandPanel` maintains `SingleChildScrollView` with safe padding.
- No new routes added (uses `IndexedStack` switching).

## Metadata
- **Risk**: TIER_1 (Feature Logic)
- **Reversibility**: HIGH
