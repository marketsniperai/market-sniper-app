# D55.16A Backend Capability Inventory Report

> **Authority:** D55.16A
> **Mode:** AUDIT (Read-Only)
> **Target:** `backend/` Codebase

## Section A: Backend Route Inventory

The following relevant endpoints exist in `backend/api_server.py`:

| Path | Method | Access | Returns |
| :--- | :--- | :--- | :--- |
| `/lab/war_room` | GET/HEAD | Founder (Header) | Unified Module Snapshot (`WarRoom.get_dashboard()`) |
| `/lab/warroom` | GET | Founder | Alias for above |
| `/lab/os/iron/status` | GET | Public* | Iron OS Status or 404 (if unavailable) |
| `/misfire` | GET | Public | Misfire Status (`check_misfire_status`) |
| `/lab/os/self_heal/housekeeper/status` | GET | Public | JSON or 404 (Reads Proof) |
| `/lab/os/self_heal/autofix/tier1/status` | GET | Public | JSON or 404 (Reads Proof) |
| `/os/state_snapshot` | GET | Public | Institutional State Snapshot |
| `/lab/os/iron/drift` | GET | Public | Iron Drift Report or 404 |
| `/lab/os/iron/replay_integrity` | GET | Public | Integrity Report or 404 |
| `/lab/replay/day` | POST | Founder | **STUB** (Returns `UNAVAILABLE`) |
| `/lab/os/rollback` | POST | Founder | **STUB** (Returns `UNAVAILABLE`) |
| `/health_ext` | GET/HEAD | Public | `RunManifest` (Pipeline Truth) |
| `/options_context` | GET | Public | Options Engine Context (or generated N/A) |

*\* "Public" here means defined without explicit `founder_middleware` check in the function body, though `PublicSurfaceShieldMiddleware` guards `/lab` prefix broadly.*

---

## Section B: Module Coverage Matrix

| Module | Backend Logic? | Endpoint? | Included in War Room Snapshot? | Gating |
| :--- | :--- | :--- | :--- | :--- |
| **OS_HEALTH** | YES | `/health_ext` | **IMPLICIT** (Derived from Reachability) | Public |
| **AUTOPILOT** | YES | `/autofix` | **YES** (`modules.autofix`) | Public |
| **MISFIRE** | YES | `/misfire` | **YES** (`modules.misfire`) | Public |
| **HOUSEKEEPER**| YES | `/.../housekeeper/status`| **YES** (`modules.housekeeper`) | Shielded (`/lab`) |
| **IRON_OS** | YES | `/lab/os/iron/status` | **YES** (`modules.iron_os_status`) | Shielded (`/lab`) |
| **REPLAY** | PARTIAL (Stub)| `/lab/replay/day` | **NO** (Missing explicit key, likely derived) | Founder |
| **UNIVERSE** | YES | N/A | **NO** (Missing explicit key in snapshot) | N/A |
| **IRON_LKG** | YES | N/A | **NO** (Missing explicit key, likely part of Iron OS) | N/A |
| **DRIFT** | YES | `/lab/os/iron/drift` | **NO** (Missing key in snapshot, has own endpoint) | Shielded (`/lab`) |
| **RED_BUTTON** | NO | N/A | **NO** | Frontend-Only? |

**Findings:**
1.  **Snapshot Gaps:** The Unified War Room Endpoint (`/lab/war_room`) returns a rich object, but *misses* explicit top-level keys for `universe`, `replay`, `iron_lkg`, and `drift` (though drift has its own endpoint). The frontend likely expects these to be merged or calls them separately? (Actually, War Room V2 design usually demands a single Unified Snapshot).
2.  **Implementation Exists:** The logic to fetch these exists (e.g., `IronOS.get_drift_report()`), it's just not aggregated into `WarRoom.get_dashboard()`.

---

## Section C: Gating & Error Semantics

1.  **PublicSurfaceShieldMiddleware:**
    *   **Rule:** Blocks paths starting with `/lab`, `/forge`, `/internal`, `/admin`.
    *   **Response:** `403 Forbidden` (JSON).
    *   **Impact:** All `/lab/*` endpoints (War Room, Housekeeper, Iron OS) are unreachable from the "Public" internet unless the `X-Founder-Key` bypasses it (which it doesn't seem to do in the middleware logic—it's a hard check on path). *Wait, if this is a hard 403 on `/lab`, how does the Founder access it?* **Answer:** `api_server.py:71` shows a HARD DENY for `/lab`. This implies these endpoints are ONLY accessible if that middleware is disabled or if the user is "Local" (detected how? Middleware doesn't seem to exempt localhost). **CRITICAL:** This middleware might be blocking *everyone* on `/lab` routes if active.

2.  **Founder Middleware:**
    *   **Rule:** Adds `X-Founder-Trace: KEY_SENT={bool}`.
    *   **Impact:** Does *not* block request, just annotates it. Individual endpoints check `request.headers.get("X-Founder-Key")`.

3.  **StripApiPrefixMiddleware:**
    *   **Rule:** Strips `/api/` prefix.
    *   **Impact:** Allows Firebase Hosting (`/api/health_ext`) to map to Backend (`/health_ext`). Essential for Web Client.

---

## Section D: Canon Debt Index Path

*   **Existence:** `pending_index_v2.json` is referenced in the UI.
*   **Static File:** Not found in `backend/` file listing (which was partial) but `backend/artifacts` exists.
*   **Route:** **NO ROUTE FOUND** in `api_server.py` serving `pending_index_v2.json` or mapping `/fs/` or `/canon/` static paths.
*   **Conclusion:** The backend does **NOT** serve this file. It is likely expected to be hosted by Firebase Hosting (Frontend Assets) or is simply missing wiring.

---

## Section E: Decision & Root Cause

**Decision:**
The primary "Blackout" observed by the User (Fetch 404) is a **Liveness/Wiring Issue**, NOT a "Missing Implementation" issue for the core modules.

**Root Cause:**
1.  **Backend OFF:** The immediate cause of "Everything Unavailable" is the backend process being offline locally. `dev_ritual.ps1` fixes this.
2.  **Shielding Risk:** The `PublicSurfaceShieldMiddleware` appears to hard-block `/lab/*` routes without an obvious exemption for the Founder Key or Localhost. This *might* cause 403s even when Backend is ON.
3.  **Snapshot Incompleteness:** The `War_room.get_dashboard()` method aggregates *most* modules but misses `universe`, `drift`, `replay` keys, causing those specific tiles to potentially remain "Grey/Unavailable" even when the War Room is Green.

**Recommendation:**
1.  **EXECUTE RITUAL:** Verify Liveness first.
2.  **VERIFY SHIELD:** Check if `/lab/war_room` returns 403 locally. (If so, Middleware needs a "Local/Founder Override").
3.  **EXPAND SNAPSHOT:** Update `WarRoom.get_dashboard()` to include the missing keys (`drift`, `universe` status) to light up the remaining tiles.
