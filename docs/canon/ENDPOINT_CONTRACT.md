# ENDPOINT CONTRACT (G0.CANON_1)

**Authority:** IMMUTABLE
**Sync Date:** Day 31 (The Surgeon)

## 1. Endpoint Classification

### 1.1 Public (Core)
*Accessible to all clients. Fail-safe behavior required.*

| Route | Method | Source Artifact | Gating | Fail Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **/health_ext** | GET | `full/run_manifest.json` | None | 200 (Degraded) |
| **/dashboard** | GET | `full/dashboard_market_sniper.json` | None | 200 (Empty/Stale) |
| **/context** | GET | `full/daily_predictions.json` | None | 200 (Empty) |
| **/misfire** | GET | `misfire_report.json` | None | 200 (Status) |
| **/pulse** | GET | `light/run_manifest.json` | None | 200 (Stale) |

### 1.2 Operations & War Room (Ops)
*High-privilege. STRICT isolation.*

| Route | Method | Action | Gating | Fail Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **/lab/war_room** | GET | Full System Dashboard | `X-Founder-Key` | 404 (Hidden) |
| **/lab/run_pipeline** | POST | Trigger Pipeline | `X-Founder-Key` | 404 (Hidden) |
| **/lab/autofix/execute** | POST | Execute Playbook | `X-Founder-Key` | 404 (Hidden) |
| **/lab/shadow_repair/propose** | POST | Generate Patch Proposal | `X-Founder-Key` | 404 (Hidden) |
| **/autofix** | GET | Autofix Status | None (Public Read) | 200 |
| **/housekeeper** | GET | Housekeeper Status | None (Public Read) | 200 |

### 1.3 Intelligence (AGMS)
*Traceability into the "Thinking" layer.*

| Route | Method | Action | Gating | Fail Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **/agms/foundation** | GET | Foundation Snapshot | None | 200 |
| **/agms/intelligence** | GET | Intel Snapshot | None | 200 |
| **/agms/handoff** | GET | Handoff Token | None | 200 |
| **/agms/thresholds** | GET | Dynamic Thresholds | None | 200 |

## 2. Response Standards
- **Success**: 200 OK.
- **Maintenance**: 503 Service Unavailable (with `Retry-After`).
- **Hidden**: 404 Not Found (for sensitive ops endpoints w/o Key).
- **Structure**: All JSON responses must be wrapped (no raw lists).
