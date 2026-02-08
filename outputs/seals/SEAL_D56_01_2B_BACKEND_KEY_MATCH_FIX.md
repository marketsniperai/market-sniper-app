# SEAL: D56.01.2B — 403 WITH KEY_SENT=True (BACKEND KEY VALIDATION FIX)

> **Date:** 2026-02-05
> **Author:** Antigravity (Agent)
> **Task:** D56.01.2B
> **Status:** SEALED
> **Type:** MICRO-FIX

## 1. Context (The Ghost 403)
Even with `KEY_SENT=True` (Header Injected), the Backend returned **403 Forbidden**.
Trace showed `FOUNDER_BUILD=TRUE`, implying `is_founder_mode` was active, but the key comparison failed.

## 2. Phase 1: Investigation & Logs
-   **Hypothesis**: The Frontend sent `mz_founder_888` (Debug Default), but the Backend Environment had a different key (Session Mismatch or Empty).
-   **Logging Probe**: Injected middleware logs revealed the mismatch scenario.
-   **Root Cause**: `dev_ritual.ps1` (and manual `flutter run`) did not enforce a consistent `FOUNDER_KEY` between the Backend process and the Frontend build.

## 3. Phase 2: Probe Reality (Curl)
-   **Hostile Probe**: `curl ...` (No Header) -> **403 Forbidden** (Logged "SHIELD: DENY").
-   **Founder Probe**: `curl -H "X-Founder-Key: mz_founder_888" ...` -> **405 Method Not Allowed** (Auth Success, Logic Fail on HEAD).
-   **Confirmation Probe**: `curl` (GET) -> **200 OK** (Payload Received).
-   **Conclusion**: Backend **does** accept `mz_founder_888` IF started with that key in the environment.

## 4. Phase 3: The Fix (Dev Ritual)
-   **Action**: Updated `tools/dev_ritual.ps1` to:
    1.  **Auto-Unlock**: Default `$founderKey` to `mz_founder_888` if not provided (matching `AppConfig` default).
    2.  **Environment Inheritance**: Explicitly injected `$env:FOUNDER_KEY` into the `Start-Process` command string for the Backend.
-   **Result**: Ensuring `dev_ritual.ps1` is the Single Source of Truth for the local dev session key.

## 5. Manifest
-   `backend/api_server.py` (Instrumented & Reverted)
-   `tools/dev_ritual.ps1` (Key Injection Logic Updated)

## Pending Closure Hook
- Resolved Pending Items:
  - None (Legacy Seal Retrofit)
- New Pending Items:
  - None
