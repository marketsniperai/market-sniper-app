# ARTIFACT CONTRACT (G0.CANON_1)

**Authority:** IMMUTABLE
**Sync Date:** Day 31 (The Surgeon)

## 1. Artifacts Root
All system artifacts must reside in the canonical **Artifacts Root**.
*   **Local Dev**: `backend/outputs/`
*   **Cloud Run**: `/app/backend/outputs`
*   **Persistence**: GCSFuse mounted bucket.

## 2. Core Artifacts Inventory

### 2.1 System Truth (Core)
| Artifact | Producer | Consumer | Freshness |
| :--- | :--- | :--- | :--- |
| **full/run_manifest.json** | Pipeline (Full) | Gates | < 26 h |
| **light/run_manifest.json** | Pipeline (Light) | Gates | < 15 min |
| **misfire_report.json** | Misfire Monitor | Misfire Endpoint | < 30s |

### 2.2 Autonomy & Ops (Runtime)
| Artifact | Producer | Consumer | Purpose |
| :--- | :--- | :--- | :--- |
| **runtime/agms/agms_foundation.json** | AGMS Foundation | Intel | Base system state. |
| **runtime/agms/agms_intelligence.json** | AGMS Intel | Shadow Rec | Coherence & Patterns. |
| **runtime/agms/agms_stability_band.json** | AGMS Bands | Policy | Traffic light (Green/Orange). |
| **runtime/agms/agms_handoff.json** | AGMS Handoff | Autofix | Signed intent from thinking layer. |
| **runtime/autopilot/autopilot_policy_snapshot.json** | Policy Engine | War Room | Shows current mode (Shadow/Safe). |
| **runtime/autofix/autofix_ledger.jsonl** | Autofix | War Room | Ledger of all executed actions. |
| **runtime/shadow_repair/patch_proposal.json** | Shadow Repair | Founder | Proposed unified diffs. |
| **runtime/shadow_repair/shadow_repair_ledger.jsonl** | Shadow Repair | War Room | Ledger of Surgeon actions. |

### 2.3 User Experience (Feature)
| Artifact | Producer | Consumer | Freshness |
| :--- | :--- | :--- | :--- |
| **full/dashboard_market_sniper.json** | Dashboard | App | < 24h |
| **full/daily_predictions.json** | Context | App | < 24h |

## 3. Laws of Production
1. **Atomic Write**: All artifacts must be written atomically (`.tmp` -> `rename`).
2. **Schema Versioning**: All core artifacts must contain a `"schema_version"` field.
3. **No Partial Writes**: An artifact is either complete or it does not exist.
4. **Backup First (Surgeon Law)**: Any runtime repair MUST backup the target first (`.bak`).
