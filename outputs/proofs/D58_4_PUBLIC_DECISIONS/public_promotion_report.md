# PUBLIC PROMOTION REPORT (D58.4)

**Batch #2 Decision Matrix**
**Date:** 2026-02-06
**Status:** EXECUTED

## 1. Objective
To reclassify "safe" read-only Unknown Zombies into the `PUBLIC_PRODUCT` tier, adhering to the "Law of the Lens" (Artifact-Backed).

## 2. Selection Criteria (Hard Rules)
- **Method:** GET only.
- **Safety:** No sensitive ops, no secrets, no Founder Key required.
- **Wiring:** Must effectively read an artifact (wired_read) or compute-to-cache (wired_compute_and_cache).
- **Fallback:** Must NEVER return 500 (handled via FallbackEnvelope).

## 3. Promoted Endpoints (10)

| Endpoint | Artifact Source | Rationale |
| :--- | :--- | :--- |
| `/agms/summary` | `runtime/agms/agms_weekly_summary.json` | High-level summary, public safe. |
| `/agms/thresholds` | `runtime/agms/agms_dynamic_thresholds.json` | Operational transparency. |
| `/efficacy` | `efficacy_report.json` | Core transparency metric. |
| `/economic_calendar` | `economic_calendar.json` | Public market data. |
| `/options_report` | `options_report.json` | Public product feature. |
| `/sunday_setup` | `sunday_setup.json` | Weekly content product. |
| `/overlay_live` | `overlay_status.json` | UI overlay state. |
| `/voice_state` | `voice_state.json` | UI voice state. |
| `/on_demand/context` | *Computed Cache* | Core product feature (safe fallbacks). |
| `/os/state_snapshot` | `os_state.json` | High-level system state for UI. |

## 4. Contract Enforcement
For each promoted endpoint, a JSON Schema (`v1`) has been created in `tools/ewimsc/contracts/`.
These schemas enforce the standard `FallbackEnvelope` structure:
- `status` (string)
- `schema_version` (string)
- `payload` (object/null)

## 5. Verification
- **Allowlist Updated:** `tools/ewimsc/zombie_allowlist.json`
- **Canon Updated:** `ZOMBIE_LEDGER.md` (moved from UNKNOWN to PUBLIC_PRODUCT).
- **Contracts Created:** 10 new schemas.
- **Harness:** `ewimsc_run.ps1` verifies schema compliance.

## 6. Impact
- **Unknown Zombies Count:** Decreased by 10 (41 -> 31).
- **Public Product Count:** Increased by 10.

**Next Steps:**
- Monitor for 500s in production (Smoke Test D58.3 confirmed basic 200/422 behavior).
- Proceed to Elite Gating (D58.5) for sensitive routes.
