# SEAL: D45 HF04 WAR ROOM WIRING AUDIT AND CANON DEBT RADAR FIX

**Date:** 2026-01-25
**Author:** Antigravity (Agent)
**Status:** SEALED (PASS)
**Verification:** Flutter Analyze (Pass) + Runtime Audit

## 1. Objective
Diagnose unavailable War Room tiles and fix `CanonDebtRadar` to strictly follow `AppConfig` (Production SSOT) instead of hardcoded `localhost`.

## 2. Findings (Audit)
- **Base URL:** `https://marketsniper-api-3ygzdvszba-uc.a.run.app` (Correct).
- **Endpoint Status:** `403 Forbidden` on `/health_ext` and `/canon/pending_index_v2.json`.
- **Root Cause:** **ACCESS_DENIED_PROD**. The Cloud Run Ingress is restricting public access, causing tiles to fail.
- **Previous Flaw:** Code was catching the error and falling back to `localhost:8000`, masking the real issue.

## 3. Changes
- **CanonDebtRadar:**
  - Removed `localhost` fallback. Now strictly uses `AppConfig.apiBaseUrl`.
  - Added **Founder Debug View**: If tile is UNAVAILABLE, Founder build sees the exact URL and Status Code (e.g., `...run.app [403]`).
  - Implemented correct fallback logic (API Route -> Static File, though both are currently 403).

## 4. Verification
- **Compilation:** PASS.
- **Runtime Logic:** Validated via Audit Probe that backend returns 403. New UI will correctly reflect this instead of silently failing on localhost.

## 5. Manifest
- `market_sniper_app/lib/widgets/war_room/canon_debt_radar.dart`
- `outputs/proofs/war_room/wiring_audit_baseurl.json`
- `outputs/proofs/war_room/war_room_endpoint_probe.json`
- `outputs/proofs/war_room/war_room_root_cause.json`
