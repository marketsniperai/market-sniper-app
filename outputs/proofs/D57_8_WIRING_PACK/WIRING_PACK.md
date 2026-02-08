# MARKET SNIPER OS - WIRING CONTEXT
**Date:** 2026-02-05T23:32:25.093530

## 1. Boot & Flow
- **Local Boot:** `tools/ewimsc/ewimsc_run.ps1` starts server at `http://127.0.0.1:8787`.
- **Cloud Boot:** Managed via Cloud Run (URL discovered in repo).
- **Flow:** Request -> `PublicSurfaceShieldMiddleware` -> Auth Check -> Handler.

## 2. Truth & Debugging
- **Truth:** Resides in `backend/outputs/` artifacts (JSON).
- **Debugging:**
  - **403:** Shield is active. Proper behavior for LAB/INTERNAL without key.
  - **Timeout:** System Failure (Regression). Must fail immediately if blocked.
  - **404:** Route does not exist OR is masquerading (Ghost).

## 3. Safe Reasoning Rules
- **Do NOT Guess:** If classification is `UNKNOWN_ZOMBIE`, it is untrusted.
- **Strict 403:** LAB_INTERNAL validation relies on exact 403 status code.
- **Artifacts Supreme:** Code logic is secondary to produced Artifact JSONs.

## 4. Inventory stats
- **Public:** 14
- **Lab:** 30
- **Zombies:** 42