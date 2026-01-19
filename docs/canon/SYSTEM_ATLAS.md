# SYSTEM ATLAS (G0.CANON_ATLAS)

**Authority:** IMMUTABLE
**Sync Date:** Day 31 (The Surgeon)

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

## 6. Elite Arc (Day 43) - COMPLETED
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
