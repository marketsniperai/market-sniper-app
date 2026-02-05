# SEAL: D49.ELITE.HF01 — Contract Sync (Ritual API)

**Date:** 2026-01-29
**Author:** Antigravity (Agent)
**Status:** SEALED

## 1. Objectives & Resolution
The objective was to unify the Elite Ritual API contract between backend and frontend, ensuring seamless compatibility and robust status handling.

### Resolutions
- **Backend Contract:**
    - Canonical: `GET /elite/ritual/{ritual_id}` (Returns Envelope)
    - Alias: `GET /elite/ritual?id=...` (Returns Envelope, calls Canonical logic)
    - Both ensure **200 OK** Envelope standard.
- **Frontend Client:** `ApiClient` (`lib/logic/api_client.dart`) updated to use Canonical Path and return the Envelope Map instead of throwing exceptions.
- **Frontend UI:** `EliteRitualModal` (`lib/widgets/elite/elite_ritual_modal.dart`) refactored.
    - Parses `status` ("OK", "WINDOW_CLOSED", "CALIBRATING", "OFFLINE").
    - Renders content if OK.
    - Renders "WINDOW CLOSED" or "CALIBRATING" screens with specific icons/colors if redundant.
- **Verification:**
    - `backend/verify_d49_elite_hf01_contract.py` confirmed logic for both IDs.
    - `flutter analyze` passed (Clean).
    - `flutter build web` passed (Exit Code 0).

## 2. Envelope Standard
```json
{
  "ritual_id": "string",
  "status": "OK | WINDOW_CLOSED | CALIBRATING | OFFLINE | ERROR",
  "as_of_utc": "ISO8601",
  "payload": { "meta": {}, "sections": [] } // or null
}
```

## 3. Next Steps
- Production deployment of backend and frontend.
- Monitor logs for "CALIBRATING" states to ensure engines are firing correctly.

## Pending Closure Hook
- Resolved Pending Items:
  - None
- New Pending Items:
  - None
