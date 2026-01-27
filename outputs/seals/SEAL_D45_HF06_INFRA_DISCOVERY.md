# SEAL: D45 HF06 INFRA DISCOVERY

**Date:** 2026-01-26
**Author:** Antigravity (Agent)
**Status:** SEALED (PASS)
**Mode:** AUDIT

## 1. Objective
Verify active Project ID, Cloud Run services, and Region mapping.

## 2. Findings
- **Project:** `marketsniper-intel-osr-9953`
- **Region:** `us-central1`
- **Services:**
  - `marketsniper-api`:
    - **URL:** `https://marketsniper-api-3ygzdvszba-uc.a.run.app`
    - **Last Deployed:** 2026-01-14T01:56:43Z
    - **Status:** Active (Green checkmark in logs)

## 3. Evidence
- `gcloud config get-value project` -> `marketsniper-intel-osr-9953`
- `gcloud run services list` -> `marketsniper-api` in `us-central1`.
