# SEAL: D55.16B.9 — FRONTEND HOTFIX (CANON DEBT RADAR ROUTE)

**Date:** 2026-02-05
**Author:** Antigravity (Agent)
**Status:** SEALED
**Classification:** FRONTEND WIRING REPAIR

## 1. Context
The **Canon Debt Radar** UI was attempting to fetch a static file path (`outputs/proofs/canon/pending_index_v2.json`) that is not mounted in the V2 backend architecture, resulting in `404 Not Found`.

The Backend Hotfix (D55.16B.8) restored the authenticated API route `/lab/canon/debt_index` (fixed 500 Error).

## 2. Actions Taken
-   **Modified `canon_debt_radar.dart`**:
    -   Changed `indexUrl` to use the authenticated **API endpoint** (`/lab/canon/debt_index`).
    -   Implemented **Header Injection** for `X-Founder-Key` strictly for Founder Builds, ensuring compatibility with the Backend Shield.
    -   Removed reliance on legacy query parameters for the Index fetch.

## 3. Verification
-   **Static Analysis**: `flutter analyze` passed cleanly.
-   **Logic Check**:
    -   Url: `$baseUrl/lab/canon/debt_index` (Correct)
    -   Auth: `headers['X-Founder-Key']` injected (Correct)
-   **Runtime Expectation**:
    -   Founder Mode + Debug -> Key Injected -> Backend 200 OK -> UI displays Debt Index.
    -   Snapshot fetch remains static (may 404), but UI is resilient (integrity status `NO_BASELINE`).

## 4. Artifacts
-   **Modified**: `market_sniper_app/lib/widgets/war_room/canon_debt_radar.dart`
-   **Updated**: `PROJECT_STATE.md`, `OMSR_WAR_CALENDAR`

## 5. Status
**D55.16B.9 COMPLETE.** Frontend wiring is now aligned with Backend reality.
## Pending Closure Hook

Resolved Pending Items:
- [ ] (None)

New Pending Items:
- [ ] (None)
