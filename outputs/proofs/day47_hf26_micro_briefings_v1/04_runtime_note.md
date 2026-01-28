# Runtime Verification Note
**Feature:** HF26 — Intel Cards v1 (Micro-Briefings)
**Date:** 2026-01-28

## Verification Context
Headless environment. Verification relies on logic inspection and sample payload validation.

## Logic Verification
1.  **Dependencies:** `IntelCard` integrated into `OnDemandPanel`.
2.  **Card 1: Evidence (Probability)**
    - **Source:** `inputs.evidence.metrics` (win_rate, avg_return).
    - **Logic:**
        - If `win_rate` present -> Show % and color (High/Med/Low).
        - If missing -> Show "Insufficient historical matches" (CALIBRATING).
3.  **Card 2: Catalyst Radar (News)**
    - **Source:** `inputs.news.headlines` (Top 3).
    - **Logic:**
        - If present -> Show headlines, Green accent.
        - If missing -> Show "Radar OFFLINE" (Gray accent).
4.  **Card 3: Regime & Structure**
    - **Source:** `contextTags.macro.tags`.
    - **Logic:**
        - Detects `MACRO_STUB_NEUTRAL`.
        - Defaults to "BALANCED" structure for V1.
5.  **UI Discipline:**
    - Uses `AppColors` accents (NeonCyan, Bull, Bear, Stale, TextSecondary).
    - Uses `AppTypography` labels/body.
6.  **Placement:** Successfully inserted below `ReliabilityMeter`.

## Limitations
- Visual confirmation of Tooltips requires hover test.
- Visual confirmation of accent bars requires runtime render.
