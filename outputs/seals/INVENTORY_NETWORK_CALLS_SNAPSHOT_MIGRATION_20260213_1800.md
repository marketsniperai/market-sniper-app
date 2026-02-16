# INVENTORY: NETWORK CALLS SNAPSHOT MIGRATION
**Date:** 2026-02-13
**Subject:** Baseline Forensics for Total SSOT Migration

## 1. Allowed Endpoints (Whitelist)
These endpoints are PERMITTED to remain (Writes/Telemetry).

| Method | Endpoint | Usage | File | Action |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/lab/watchlist/log` | Telemetry | `lib/services/api_client.dart` | **KEEP** |
| `POST` | `/elite/chat` | User Interaction | `lib/widgets/elite_interaction_sheet.dart` | **KEEP** (User Action) |
| `POST` | `/elite/settings` | Config Write | `lib/screens/menu_screen.dart` | **KEEP** (User Action) |

*(Note: `fetchOnDemandContext` is a specific query. If not in snapshot, it might need special handling, but strict rule says "UI may only fetch... snapshot". Marking as **BLOCK/MIGRATE** for now unless proven otherwise.)*

## 2. Legacy Reads (Must Migrate to Snapshot)
These endpoints MUST be removed from UI paths and replaced with `UnifiedSnapshotRepository`.

### A. Core Dashboards
| Method | Endpoint | File | Replacement Path |
| :--- | :--- | :--- | :--- |
| `GET` | `/dashboard` | `lib/services/api_client.dart` | `snapshot.modules.dashboard` (if exists) or decomposed |
| `GET` | `/lab/war_room` | `lib/services/api_client.dart` | `snapshot.modules.*` |
| `GET` | `/universe` | `lib/services/api_client.dart` | `snapshot.modules.universe` |
| `GET` | `/misfire` | `lib/services/api_client.dart` | `snapshot.modules.misfire` |
| `GET` | `/system_health` | `lib/services/api_client.dart` | `snapshot.os_health` |
| `GET` | `/health_ext` | `lib/services/api_client.dart` | `snapshot.os_health` |
| `GET` | `/lab/os/health` | `lib/services/api_client.dart` | `snapshot.os_health` |

### B. Detailed Contexts
| Method | Endpoint | File | Replacement Path |
| :--- | :--- | :--- | :--- |
| `GET` | `/options_context` | `lib/services/api_client.dart` | `snapshot.modules.options` |
| `GET` | `/macro_context` | `lib/services/api_client.dart` | `snapshot.modules.macro` |
| `GET` | `/economic_calendar` | `lib/services/api_client.dart` | `snapshot.modules.calendar` (or check payload) |
| `GET` | `/news_digest` | `lib/services/api_client.dart` | `snapshot.modules.news` |
| `GET` | `/evidence_summary` | `lib/services/api_client.dart` | `snapshot.modules.evidence` |
| `GET` | `/overlay_live` | `lib/services/api_client.dart` | `snapshot.modules.overlay` (or n/a) |
| `GET` | `/projection/report` | `lib/widgets/dashboard/regime_sentinel_widget.dart` | **UNAVAILABLE** (Strict Snapshot Only) |

### C. OS Internals (Iron/Self-Heal)
| Method | Endpoint | File | Replacement Path |
| :--- | :--- | :--- | :--- |
| `GET` | `/lab/os/iron/status` | `lib/services/api_client.dart` | `snapshot.modules.iron_os` |
| `GET` | `/lab/os/iron/timeline_tail` | `lib/services/api_client.dart` | `snapshot.modules.iron_os.timeline` (if populated) |
| `GET` | `/lab/os/iron/state_history` | `lib/services/api_client.dart` | **REMOVE** (Heavy, likely not in snapshot) |
| `GET` | `/lab/os/iron/lkg` | `lib/services/api_client.dart` | `snapshot.modules.iron_lkg` |
| `GET` | `/lab/os/iron/decision_path` | `lib/services/api_client.dart` | `snapshot.modules.iron_os.decision_path` |
| `GET` | `/lab/os/iron/drift` | `lib/services/api_client.dart` | `snapshot.modules.drift` |
| `GET` | `/lab/os/iron/replay_integrity` | `lib/services/api_client.dart` | `snapshot.modules.replay` |
| `GET` | `/lab/os/self_heal/housekeeper/status` | `lib/services/api_client.dart` | `snapshot.modules.housekeeper` |
| `GET` | `/lab/os/self_heal/findings` | `lib/services/api_client.dart` | `snapshot.modules.findings` |
| `GET` | `/lab/os/self_heal/before_after` | `lib/services/api_client.dart` | **REMOVE** |
| `GET` | `/lab/os/self_heal/autofix/tier1/status` | `lib/services/api_client.dart` | `snapshot.modules.autofix_tier1` |

### D. Elite & Special
| Method | Endpoint | File | Replacement Path |
| :--- | :--- | :--- | :--- |
| `GET` | `/elite/os/snapshot` | `lib/widgets/elite_interaction_sheet.dart` | `snapshot.modules` (Unified) |
| `GET` | `/elite/state` | `lib/logic/api_client.dart` | **REMOVE/MIGRATE** |
| `GET` | `/elite/ritual/*` | `lib/logic/api_client.dart` | **REMOVE** (On-demand) |
| `GET` | `/on_demand/context` | `lib/services/api_client.dart` | **REMOVE** (Strict Snapshot Only) |

## 3. Migration Strategy
1.  **Repository Foundation**: Build `UnifiedSnapshotRepository` to fetch `/lab/war_room/snapshot`.
2.  **Global Policy**: Enforce `SNAPSHOT_ONLY` mode in `ApiClient` which throws exception for all "Legacy Reads".
3.  **UI Rewiring**:
    *   Dashboard: Read from `UnifiedSnapshotRepository`.
    *   War Room: Read from `UnifiedSnapshotRepository`.
    *   Universe: Read from `UnifiedSnapshotRepository`.
    *   Elite: Partial degrade (Elite specific endpoints might be blocked).
    *   On-Demand: Blocked by default in this mode? (Prompt says "Total UI Migration... UI screens/widgets must not call legacy endpoints directly").

**Verdict**: READY FOR IMPLEMENTATION.
