# ENDPOINT CONTRACT (G0.CANON_1)

**Authority:** IMMUTABLE

## 1. Endpoint Classification

### 1.1 Public (Core)
*Accessible to all clients. Fail-safe behavior required.*

| Route | Method | Source Artifact | Gating | Fail Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **/health_ext** | GET | `run_manifest.json` | None | 200 (Degraded) |
| **/dashboard** | GET | `dashboard_market_sniper.json` | None | 200 (Empty/Stale) |
| **/context** | GET | `daily_predictions.json` | None | 200 (Empty) |

### 1.2 Elite / Gated
*Accessible to premium users. Strict entitlement checks.*

| Route | Method | Source / Action | Gating | Fail Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **/entitlement** | GET | User DB / Auth | Bearer Token | 401/403 |
| **/watchlist** | GET | `watchlist_context.json` | Elite Only | 403 |

### 1.3 Lab / Founder (Ops)
*High-privilege. STRICT isolation.*

| Route | Method | Action | Gating | Fail Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **/lab/run_pipeline** | POST | Trigger Pipeline | `X-Founder-Key` | 404 (Hidden) |
| **/lab/founder_war_room** | GET | Dump `founder_state.json` | `X-Founder-Key` | 404 (Hidden) |
| **/lab/misfire_autoheal** | POST | Trigger Autoheal | `X-Founder-Key` | 404 (Hidden) |

## 2. Response Standards
- **Success**: 200 OK.
- **Maintenance**: 503 Service Unavailable (with `Retry-After`).
- **Hidden**: 404 Not Found (for sensitive ops endpoints).
- **Structure**: All JSON responses must be wrapped (no raw lists).
