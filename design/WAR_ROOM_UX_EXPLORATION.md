# War Room UX Exploration: Institutional Command

**Status:** DRAFT
**Context:** D52 Design Exploration
**Goal:** Transform the War Room from a demo dashboard into a dense, calm, institutional command center.

---

## 1. Research: Operations & Command Patterns (Conceptual)

We analyzed high-stakes operational interfaces (Mission Control, Trading Desks, Cloud Ops) to extract core principles.

### A. The "Silent Cockpit" Principle
*Concept:* A healthy system should be boring.
*Application:* Avoid "Christmas Tree" dashboards where green lights compete for attention. Green should be dim or implicit. Red/Orange/Yellow should be the only high-contrast elements.
*Rule:* "If everything is OK, the screen is mostly dark/monochrome."

### B. High Density, Low Noise
*Concept:* Operators prefer density over whitespace. Scrolling is the enemy of situational awareness during an incident.
*Application:* Use tabular data, sparklines, and compact status signaling instead of large "cards" with padding.
*Rule:* "Information Density > Whitespace."

### C. The hierarchy of "Zoom"
*Concept:* Three levels of attention:
1.  **Global Status:** (Is the house on fire?) -> Top Bar / Header.
2.  **System Health:** (Which room is hot?) -> Main Grid.
3.  **Diagnostic Detail:** (Why is it hot?) -> Drill-down / Side Panel.

---

## 2. Information Architecture (IA)

### Proposed Zones

```mermaid
graph TD
    A[Global Command Bar] --> B[Main Workspace]
    B --> C[Zone 1: The Pulse (Signals)]
    B --> D[Zone 2: The Machine (Infrastructure)]
    B --> E[Zone 3: The Truth (Logs/Console)]
    A --> F[Action GATES]
```

#### Zone 1: Global Command Bar (Fixed Top)
*   **Purpose:** Instant situational awareness.
*   **Content:**
    *   System Clock (UTC/ET).
    *   Global Defcon/Mode (LIVE, SAFE, CALIBRATING).
    *   Overall Health Score (0-100%).
    *   "Red Button" Access (Guarded).

#### Zone 2: The Pulse (Intelligence Layer)
*   **Purpose:** Market reality & Alpha signals.
*   **Content:**
    *   Market Regime (Bull/Bear/Crab).
    *   Alpha Signals (Ticker/Score).
    *   *Visualization:* Compact " Ticker Tape" or "Heatmap Strip" rather than big cards.

#### Zone 3: The Machine (Infrastructure Layer)
*   **Purpose:** Backend health & Wiring.
*   **Content:**
    *   Service Grid (API, Engines, Database).
    *   Latency Metrics.
    *   Memory/CPU Pressure.
    *   *Visualization:* High-density "Honeycomb" or "Cell Grid". Green = Dim Gray, Red = Bright Red.

#### Zone 4: The Truth (Context Layer)
*   **Purpose:** What just happened?
*   **Content:**
    *   System Event Log (Compact text).
    *   Misfire/Error Stream.
    *   *Visualization:* Terminal-like log view (monospace, high density).

---

## 3. Visual Hierarchy Rules

### A. The Card vs. Row Rule
*   **Rule:** "Cards are for *Containers*, Rows are for *Items*."
*   *Bad:* A card for every service (takes up too much space).
*   *Good:* A single "Services" card containing a dense TABLE or GRID of individual service rows/cells.

### B. Size Discipline & The Grid
*   **Rule:** "All elements must snap to a strict 4px/8px grid."
*   *Constraint:* Widgets must have fixed or max-heights to prevent one noisy log from pushing critical signals off-screen.
*   *Typography:*
    *   **Labels:** Sans-serif (Inter/Roboto), distinct, muted (Opacity 0.7).
    *   **Values/IDs:** Monospace (JetBrains Mono/Fira Code), high contrast.

### C. Color Semantics (The Traffic Light Protocol)
*   **GREEN:** Implied/Dim (`Colors.green.withOpacity(0.2)`). visible code, but not shouting.
*   **YELLOW/ORANGE:** Warning/Degraded. High visibility.
*   **RED:** Critical/Down. Maximum visibility (Glow effects allowed).
*   **GRAY:** Unavailable/Unknown. Low visibility, Neutral. *Crucial:* Do not make "Unavailable" look like an error. It is a lack of data, not necessarily a failure.

---

## 4. Proposed Layout Variants

### Variant A: "Founder Dense" (The Cockpit)
*   **Philosophy:** Maximum visibility, assumed expertise.
*   **Structure (4-Column Grid):**
    *   **Col 1 (Left 20%):** Navigation Rail + Global Status (Clock/Mode/Health).
    *   **Col 2 (Center-Left 30%):** Service "Honeycomb" Grid (All engines/APIs status) + Database metrics.
    *   **Col 3 (Center-Right 30%):** Intelligence/Alpha Stream (Ticker tape, Signals).
    *   **Col 4 (Right 20%):** Event Log (Terminal style) + Action Gates (Bottom).
*   **Pros:** Everything visible at once. Zero clicks to see health.
*   **Cons:** Overwhelming for non-experts (not an issue here).

### Variant B: "Tactical Overview" (The Situational Map)
*   **Philosophy:** Focus on *flow* and *regime*.
*   **Structure (Header + 3 Columns):**
    *   **Header:** Global Status Bar (Full width).
    *   **Col 1 (Input 25%):** Data Sources & Wiring Health. (Is data coming in?)
    *   **Col 2 (Processing 50%):** The "Brain" visualization. Large central view of Market Regime & Alpha generation.
    *   **Col 3 (Output 25%):** Action Log & Founder Controls.
*   **Pros:** Better narrative (Input -> Process -> Output).
*   **Cons:** Less raw density for infrastructure monitoring.

---

## 5. War Room UX Principles (Canon-Candidate)

1.  **Silence by Default:** If the system is healthy, the screen should be visually quiet. Color is a scarce resource reserved for anomalies.
2.  **Density is Safety:** Scrolling hides fire. Critical metrics must fit "above the fold" on a standard 1080p/1440p terminal.
3.  **Unavailable is Neutral:** A gray "N/A" is better than a red "ERROR". Distinguish between "Broken" and "Not Yet Calculated".
4.  **No Dead Ends:** Every widget should be clickable to reveal its source (JSON trace, log tail, or config).
5.  **Deliberate Action:** "Red Buttons" (Run/Stop/Rollback) must be separated from Read-Only data. They require a specific "Arming" gesture or distinct screen area.

---

## 6. Recommendation

**Adopt Variant A ("Founder Dense").**
*Reasoning:* The MarketSniper OS is a complex, multi-engine system. The Founder needs to see the correlation between *Infrastructure Health* (Col 2) and *Alpha Generation* (Col 3) simultaneously to trust the output. Hiding one behind tabs (as in Variant B) obscures the reality of the machine.

**Next Steps:**
1.  Prototype the "Global Command Bar" and "Service Honeycomb".
2.  Refactor existing "Tiles" into dense "Data Cells".
