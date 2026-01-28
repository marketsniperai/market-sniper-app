# ON-DEMAND AREA SEAL: CAPSTONE [FROZEN]

**Date:** 2026-01-28
**Scope:** HF22-HF33 (On-Demand Intelligence)
**Status:** FROZEN / PRODUCTION-READY
**Proof Pack:** `outputs/proofs/on_demand_area_seal/`

## 1. Identity & Purpose
The **On-Demand Engine** is the primary "Intelligence Dossier" generator for MarketSniper AI. It allows users to request instant, high-fidelity projection reports for any ticker in the universe, bounded by strict cost and tiering policies.

## 2. Truth Model (Source Ladder)
Data integrity is governed by the **Source Ladder**, ensuring no dead ends:
1.  **PIPELINE (Primary):** Fresh computation via `ProjectionOrchestrator` -> `DecryptionRitual`.
2.  **CACHE (Fallback):**
    - **Global Cache:** `outputs/on_demand_public/` (Shared across users).
    - **Local Cache:** `outputs/cache/on_demand/` (Client-specific).
    - **Resolution:** "Latest Available" policy (HF32) serves cache if limits are hit.
3.  **OFFLINE (Last Resort):** `RecentDossierStore` snapshots (HF-RECENT-LOCAL).

## 3. Surfaces & Gating
| Surface | Feature | Governance (Tier) |
|:--- |:--- |:--- |
| **Time-Traveller Chart** | History + Future Projection | **FREE:** Blurred Future. **PLUS/ELITE:** Clear. |
| **Tactical Playbook** | Watch Items / Invalidation | **FREE:** Blurred Text. **PLUS/ELITE:** Clear. |
| **Reliability Meter** | Confidence Score / Gauge | All Tiers (Visual Only). |
| **Intel Cards** | Micro-Briefings (Grid) | All Tiers. |
| **Mentor Bridge** | AI Chat / Guidance | **FREE/PLUS:** Locked. **ELITE:** Unlocked. |
| **Share Mini-Card** | Safe Viral Artifact | All Tiers (No PII, No Premium Intel). |
| **Recent Dossiers** | Quick-Load Rail | All Tiers (Local Persistence). |

## 4. Monetization & Access (HF31)
- **Resolver:** `OnDemandTierResolver` (Founder > Elite > Plus > Free).
- **Free Tier:** Core access, but Future/Tactical visuals are blurred (HF30).
- **Plus Tier:** Daily unlocks via "5-Step Ritual". Unlocks Visuals. Mentor Locked.
- **Elite Tier:** Full access. Mentor Bridge Unlocked.

## 5. Cost Policy & Limits (HF32)
- **Rule:** One manual computation per Ticker per Day (ET).
- **Enforcer:** `ComputationLedger` (`/os_ops/computation_ledger.py`).
- **Behavior:**
    - If `Computed Today`: Block Compute -> Force Fetch Cache (Global/Local).
    - UI Display: "Already generated today. Showing latest cached dossier."
    - **Safety:** If blocked but Cache is MISSING, computation is ALLOWED (Truth > Cost).

## 6. Artifacts & Endpoints
- **Endpoints:**
    - `POST /on_demand/context` (Payload: `{ticker, timeframe}`)
- **Artifacts:**
    - `outputs/cache/on_demand/{TICKER}_{TF}_{TS}.json`
    - `outputs/os/ledger/computation_ledger.json`
    - `outputs/on_demand_public/{TICKER}/{TF}/{TS}.json`

## 7. Frozen Contract
This Area is **SEALED**.
- No new features.
- No layout changes.
- No logic tweaks.
- Any modification requires a **New Design Arc (Day 48+)**.

## 8. Proof References
- `01_daily_unlocked.png`: Elite View.
- `03_free_gated.png`: Free View (Blurred).
- `09_area_seal_doc.md`: Proof Pack Capstone.
