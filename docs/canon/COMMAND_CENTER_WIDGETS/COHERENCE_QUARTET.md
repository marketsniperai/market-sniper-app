# COHERENCE QUARTET (Widget Spec)

> **Authority:** ANTIGRAVITY
> **Date:** 2026-02-06
> **Type:** Premium Core Widget
> **Surface:** Command Center (Top Anchor)

## 1. Concept
The Coherence Quartet is a **visual distillation of market truth**. It does not list prices; it visualizes **confidence**.
It acts as the visual anchor of the Command Center, replacing the "Hero Header".

## 2. Data Logic
- **Input:** Snapshot of entire Universe (e.g., 50+ symbols).
- **Filter:** Sort by absolute directional confidence (Coherence Score).
- **Selection:**
    1.  **Top 2 Positive:** Highest positive Coherence Score.
    2.  **Top 2 Negative:** Highest negative Coherence Score.
- **Total:** 4 Symbols (The Quartet).

## 3. Visual Design (The "Four Chambers")
- **Layout:** Circular or Diamond arrangement divided into 4 quadrants.
- **Top Chambers (Positive):**
    - Color: `AppColors.neonCyan` (or high-energy variant).
    - Effect: Breathing glow based on score magnitude.
- **Bottom Chambers (Negative):**
    - Color: `AppColors.stateLocked` (Red) or `AppColors.marketBear`.
    - Effect: Static burn or deep pulse.

## 4. Left Side: The Chips
To the left of the visual, list the 4 symbols as elegant oval chips.
- **Style:** Glassmorphism (`AppColors.surface2` + Blur).
- **Text:** Symbol Name (e.g., "NVDA") + Score (small).
- **Interaction:** Tap to expand Tooltip.

## 5. Interaction: The "Why" Tooltip
**Contract:** Tapping a chip opens a scrollable tooltip overlay.
**Content:**
- **Headline:** "Why High Confidence?"
- **Evidence:**
    - "Macro: Tailwind (Strong)"
    - "Options: Calls Skewed > 2 Sigma"
    - "Regime: Expansion"
    - "Memory: Matches D56 Pattern"
- **Invalidation:** "Risk: Earnings in 2 days" (if applicable).

## 6. Prohibitions
- **NO** Buy / Sell buttons.
- **NO** Entry / Exit prices.
- **NO** Targets.
- **NO** "Prediction".

## 7. Gating
- **FREE:** Not visible (Frosted / Locked).
- **PLUS:** Partial visibility (Top 1 Pos / Top 1 Neg only).
- **ELITE:** Full Quartet + Full Tooltips.
