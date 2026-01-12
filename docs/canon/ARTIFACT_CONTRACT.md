# ARTIFACT CONTRACT (G0.CANON_1)

**Authority:** IMMUTABLE

## 1. Artifacts Root
All system artifacts must reside in:
`C:\MSR\MarketSniperRepo\backend\outputs\`

## 2. Core Artifacts Inventory

### 2.1 System Truth
| Artifact | Producer | Consumer | Freshness | Required |
| :--- | :--- | :--- | :--- | :--- |
| **run_manifest.json** | Pipeline (Finalizer) | /health_ext | < 5 min | **YES** |
| **os_state.json** | Iron OS Kernel | /health_ext | Permanent | **YES** |

### 2.2 User Experience
| Artifact | Producer | Consumer | Freshness | Required |
| :--- | :--- | :--- | :--- | :--- |
| **dashboard_market_sniper.json** | Dashboard Engine | /dashboard | < 24h | **YES** |
| **daily_predictions.json** | Context Engine | /context | < 24h | **YES** |
| **watchlist_context.json** | Watchlist Engine | /watchlist | < 1h | NO |

### 2.3 Founder/Lab
| Artifact | Producer | Consumer | Freshness | Required |
| :--- | :--- | :--- | :--- | :--- |
| **founder_state.json** | Iron OS | /lab/founder_war_room | Real-time | NO |
| **trace_log.json** | Forensics | /lab/trace | Real-time | NO |

## 3. Laws of Production
1. **Atomic Write**: All artifacts must be written atomically (`.tmp` -> `rename`).
2. **Schema Versioning**: All core artifacts must contain a `"schema_version"` field.
3. **No Partial Writes**: An artifact is either complete or it does not exist.
