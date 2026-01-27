# SYSTEM ATLAS (G0.CANON_ATLAS)

**Authority:** IMMUTABLE
**Sync Date:** Day 45 (Feature Phase)

## 1. Cloud Infrastructure (GCP)
- **Project ID**: `marketsniper-intel-osr-9953`
- **Region**: `us-central1`

## 2. Compute
### 2.1 Backend (Service Layer)
- **marketsniper-api**: Core Brain (FastAPI).
    - *Roles*: API Server, Autopilot Policy Engine, War Room Dashboard.
    - *Features*:
        - **Autofix Control Plane**: Orchestrates healing (Tier 1).
        - **Housekeeper**: Manages data hygiene.
        - **Shadow Repair**: Generates/Applies Patches (Propose/Surgeon).
        - **War Room**: Real-time observability interface.
    - *Auth*: Service Account `ms-api-sa`.
    - *Mounts*: `marketsniper-outputs-marketsniper-intel-osr-9953` -> `/app/backend/outputs`.

### 2.2 Pipeline (Worker Layer)
- **market-sniper-pipeline**: Heavy Lifting (Python).
    - *Roles*: Data Ingestion, Pattern Detection, Artifact Generation.
    - *Auth*: Service Account `ms-job-sa`.
    - *Mounts*: Same as API.
    - *Trigger*: 
        - Cloud Schedulers (`ms-full-0830et`, `ms-light-5min`).
        - API (via Autofix/Handoff).

## 3. Autonomous Architecture (AGMS)
### 3.1 Intelligence (The Thinker)
- **AGMS Foundation**: Ingests raw state, builds snapshot.
- **AGMS Intelligence**: Determines coherence, patterns, stability bands.
- **Shadow Recommender**: Proposes actions based on intelligence.
- **Handoff Bridge**: Cryptographically signs proposals for Autofix.

### 3.2 Operations (The Actor)
- **Autopilot Policy Engine**: The "Gatekeeper" (Autonomy Dial).
    - *Modes*: SHADOW, SAFE_AUTOPILOT, FULL_AUTOPILOT.
    - *Input*: Risk Tags + Band + Handoff Token.
    - *Output*: ALLOW/DENY.
- **Autofix Control Plane**: Executes allowed playbooks (e.g., Run Pipeline).
- **Shadow Repair (The Surgeon)**: 
    - *Propose Mode*: Generates diffs for source/contract changes (Human Review).
    - *Surgeon Mode*: Autonomously patches **RUNTIME** artifacts (Low Risk) with Rollback.
- **Iron OS (The Mirror)**:
    - *Roles*: State Management, History, Replay.
    - *Artifacts*: `os_state.json`, `iron_timeline.json`, `lkg_snapshot.json`.

## 4. Persistence
- **Bucket**: `gs://marketsniper-outputs-marketsniper-intel-osr-9953`
- **Volume Method**: GCSFuse (Gen2 Execution Environment).
- **Paths**:
    - Runtime (API/Job): `/app/backend/outputs`
    - Local Dev: `backend/outputs`
- **Artifact Classes**:
    - `full/`, `light/`: Pipeline outputs.
    - `runtime/`: Autonomous State (Ledgers, Policy Snapshots, Handoffs).
    - `seals/`: Immutable cryptographic seals of work.

## 5. Automation
- **Schedulers (Dual Cadence)**:
    - `ms-full-0830et`: 08:30 ET Daily (Full Mode).
    - `ms-light-5min`: Every 5 min (Light Mode).
- **Misfire Monitor**: Embedded in API, detects lock staleness.
- **Housekeeper**: Embedded in API, cleans drift.

## 6. Real-Time Intelligence Arc (Day 40) - COMPLETED
- **Pulse**: Real-time sector/regime state.
- **Sentinel**: Sector heatmap and active monitoring.
- **Freshness**: Real-time logic (1 min - 15 min degrade).

## 7. Iron OS Arc (Day 41) - COMPLETED
- **Iron OS**: The immutable state recorder.
- **Replay Archive**: Time travel for states (Institutional Day Replay).
- **Rollback Ledger**: Founder-gated undo capability.

## 8. Self-Heal & Housekeeper Arc (Day 42) - COMPLETED
- **AutoFix Tier 1**: Deterministic self-repair.
- **Housekeeper**: Auto-clean operational debris.
- **Misfire Tier 2**: Deep-fix logic.

## 9. Elite Arc (Day 43) - COMPLETED
- **Elite Context Memory**:
    - `day_memory.json`: Session memory (4KB/Day).
    - `session_thread_memory.json`: Thread state (12 turns).
    - `context_safety_protocol.json`: Tone & Legal rules.
- **Surface Layer**:
    - **EliteOverlay**: 70/30 Context Shell.
    - **ExplainRouter**: Safe navigation logic.
    - **LayoutPolice**: Debug guard (Founder build).
- **Automation**:
    - **Ritual Scheduler**: Local time-based triggers (Morning, Afternoon, Setup).

## 10. Watchlist & On-Demand (Day 44) - COMPLETED
- **Watchlist Store**: Local persistence, live chips, easy-add.
- **On-Demand Engine**: Universe-agnostic search (Pipeline/Cache/Offline).
- **Institutional Guard**: Lexicon enforcement on results.

## 11. Feature Phase v1 (Day 45) - COMPLETED
- **Premium Matrix**: Trial/Plus/Elite logic.
- **Share Engine**: Watermarked institutional sharing.
- **Command Center**: Elite-only mystery surface.
- **News & Calendar**: High-fidelity data surfaces.
## 12. Pending Ledger (Day 45) - ACTIVE
- **Pending Ledger**: Single Source of Truth for debt and roadmap.
- **Path**: `docs/canon/PENDING_LEDGER.md`
- **Sync**: Day 45 (Canon Debt Purge)
- **Status**: 10+ Active Items (Voice, Risk Lanes, Procedure, Lock, News Provider, etc.)
- **Machine Index (Radar Input)**: [`outputs/proofs/canon/pending_index_v2.json`](../../outputs/proofs/canon/pending_index_v2.json)
- **UI Surface**: `CanonDebtRadar` (V2.1). Fingerprint Guard + Integrity Check.

## 13. Institutional Polish (Day 46) - COMPLETED
- **Regime Sentinel**: Detailed market regime analysis and discipline buckets.
- **Watchlist 2.0**: Unrestricted memory, snappier UX, auto-clearing snackbars.
- **Widget Standard**: Breathing status accents, unified headers (Neon Cyan).

## 14. News Engine (Day 47) - ARCHITECTURE READY
- **News Demo**: Local deterministic source acting as "Premium Demo".
- **Ranking Engine**: `Macro > Watchlist > General` logic (Rules-Only, No ML).
- **UI**: Flip Cards (`NewsDigestCard`) with Impact Tags.
- **Pending**: Provider Data Pipeline (Open).

