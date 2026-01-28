# Runtime Verification Note
**Feature:** HF27 — Tactical Playbook (Watch / Invalidate)
**Date:** 2026-01-28

## Verification Context
Headless environment. Verification relies on logic inspection and sample payload validation.

## Logic Verification
1.  **Dependencies:** `TacticalPlaybookBlock` integrated into `OnDemandPanel`.
2.  **Derivation Logic (Backend):**
    - **Evidence:** High WR (>60%) triggers "High historical resolution probability".
    - **Options:** Expected Move triggers "Price action respect of volatility envelope".
    - **Catalyst:** News count triggers "Catalyst event monitoring".
    - **Defaults:** Standard fallback used if empty.
3.  **UI Logic (Frontend):**
    - **Override:** If `_isDailyLocked()` (09:30-10:30 ET), renders "CALIBRATION WINDOW" bullets.
    - **Rendering:** Uses Green/Red accents for Watch/Invalidate.
4.  **Integration:** Placed below `IntelCards`.

## Limitations
- Visual confirmation of "CALIBRATION WINDOW" requires lock window test.
