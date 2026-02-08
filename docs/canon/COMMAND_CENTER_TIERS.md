# COMMAND CENTER TIERS (D61.0)

> **Authority:** ANTIGRAVITY
> **Date:** 2026-02-06
> **Scope:** Command Center Access Control

## 1. FREE TIER
**Experience:** "The frosted glass ceiling."
- **Visibility:** Full Command Center structure is visible but heavily frosted/blurred.
- **Interactive:** No.
- **CTA:** "Unlock Command Center" (Center overlay).
- **Goal:** Show *that* truth exists, without revealing *what* it is.

## 2. PLUS TIER (The Discipline Path)
**Experience:** "Earned Authority."
- **Unlock Mechanism:** **Discipline Counter**.
    - Must maintain 5 consecutive **Market-Open Days** of valid check-ins.
    - **Counter Rules:**
        - Increments on valid check-in (Market Open days only).
        - Decrements on missed Market Open day.
        - No penalty for missed weekends/holidays.
        - Persisted locally (Device storage).
- **Access:**
    - **Global Command Bar:** Unlocked.
    - **Alpha Strip:** Unlocked (Basic tiles).
    - **Coherence Quartet:** Partial (Top 1 Pos / Top 1 Neg only).
    - **Tooltips:** Basic summary only.
- **Frosted:** "Why" details and deep forensics.

## 3. ELITE TIER (Unfair Advantage)
**Experience:** "Total Coherence."
- **Unlock Mechanism:** Elite Badge / Subscription / Founder Override.
- **Access:**
    - **Full Unfrost:** Everything is clear.
    - **Coherence Quartet:** Full 4 symbols.
    - **Deep Tooltips:** Full evidence chains (Macro, Options, Regime).
    - **Unfair Advantage Signals:** `AppColors.neonCyan` indicators.

## 4. Implementation Note
- **Fail-Safe:** If network fails, fail to "Local State" (allow access if previously unlocked).
- **Defaults:** New install = FREE (unless Founder build).
