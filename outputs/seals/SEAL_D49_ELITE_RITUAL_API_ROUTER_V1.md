# SEAL: D49.ELITE.RITUAL_API_ROUTER_V1 — Elite Ritual API Router v1

**Date:** 2026-01-29
**Author:** Antigravity (Agent)
**Status:** SEALED

## 1. Objectives & Resolution
The objective was to implement a unified backend entry point for Elite Rituals that handles on-demand generation and standardized "Always 200 OK" responses.

### Resolutions
- **Router Logic:** `EliteRitualRouter` (`backend/os_intel/elite_ritual_router.py`) implemented.
    - Maps 6 ritual keys to engines.
    - Enforces `EliteRitualPolicy` visibility.
    - Generates artifact via Engine if window is OPEN but file is missing (Lazy Loading).
    - Returns `WINDOW_CLOSED` if window is closed.
    - Returns `CALIBRATING` if generation fails or visible-but-missing-outside-window.
- **API Endpoint:** `GET /elite/ritual/{ritual_id}` in `backend/api_server.py`.
    - Delegates to Router.
    - Always returns standardized JSON Envelope (never 404/500).
- **Verification:** `backend/verify_d49_elite_ritual_api_router_v1.py` confirmed correct status codes and payloads for known/unknown IDs.

## 2. Envelope Structure
```json
{
  "ritual_id": "morning_briefing",
  "status": "OK",  // OK | CALIBRATING | WINDOW_CLOSED | OFFLINE | ERROR
  "as_of_utc": "2026-01-29T20:00:00Z",
  "payload": { ... }, // Null if not OK
  "details": "..." // Optional debug info
}
```

## 3. Next Steps
- Frontend `ApiClient` needs to be updated to parse this new Envelope structure (currently expects direct payload or throws on 404). This will be handled in the next Prompt (D49.ELITE.RITUAL_MODALS_WIRING_V1 was done, but now we changed the contract, so we might need a quick fix or the next prompt "Polish" will handle it).
- **Note:** The user's next prompt might be to polish/update frontend to match this new contract.
