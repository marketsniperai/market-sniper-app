# MODULE COHERENCE WIRING LAW (Day 31)

> "A House Divided Cannot Stand."

This document establishes the canonical schema and wiring laws for all modules within the MarketSniper OS. Every operable unit must be registered and wired according to this law to ensure system coherence, auditability, and autonomous recovery.

## Handoff Law (The Bridge)
The most critical wiring law is the **Separation of Concerns** between Intelligence (Thinking) and Operations (Doing).
- **Intelligence Modules (AGMS)** generate `Shadow Suggestions` (Thoughts).
- **Shadow Suggestions** are signed into `Handoff Tokens` (Intent).
- **Control Plane (AutoFix)** consumes `Handoff Tokens` and submits them to the **Policy Engine** (The Gate).
- **Policy Engine** evaluates `Risk` vs `Band` and issues `ALLOW/DENY`.
- **Autofix** executes ONLY if `ALLOW`.

## Module Schema

Each module entry in the registry must contain the following fields:

### 1. Identity
*   **module_id**: Unique identifier (e.g., `OS.Infra.API`, `OS.Intel.AGMS`).
*   **name**: Human-readable name.
*   **type**: `CORE`, `OPS`, `INTELLIGENCE`, or `FEATURE`.
*   **owner**: `FOUNDER`, `AGMS`, `HOUSEKEEPER`, or `SYSTEM`.
*   **status**: `ACTIVE`, `DEPRECATED`, `EXPERIMENTAL`.

### 2. Physical Footprint
*   **primary_files**: List of critical source files that define the module (relative paths).

### 3. Wiring (The Nervous System)
*   **inputs**: Truth sources consumed (Artifacts, Ledgers, Configs).
*   **outputs**: Artifacts or Events produced.
*   **ports**: Callable entry points (API Endpoints, Public Functions).
*   **dependencies**:
    *   `upstream`: Modules this module depends on.
    *   `downstream`: Modules that depend on this one.

### 4. Governance (The Law)
*   **contracts**:
    *   `sla`: Performance or freshness expectations.
    *   `artifacts`: Required schemas for inputs/outputs.
*   **playbooks**: Recovery mapping (e.g., "Run Rebuild Job") or `N/A`.
*   **war_room_visibility**: Keys or artifact pointers for War Room display.

## Coherence Principles
1.  **No Hidden Dependencies**: All inputs and outputs must be declared.
2.  **Explicit Wiring**: Modules connect via defined Ports and Artifacts, not hidden state.
3.  **Observability**: Every module must emit status to a observable surface (War Room, Logs, or Artifacts).
4.  **Autonomy Readiness**: All OPS modules must list their `playbooks`. All INTEL modules must list their `outputs` consumed by Handoff.
