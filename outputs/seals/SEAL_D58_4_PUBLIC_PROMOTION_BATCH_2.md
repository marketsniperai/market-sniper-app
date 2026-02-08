# SEAL: D58.4 PUBLIC PROMOTION BATCH 2

**Do verify the following context before proceeding**:
- [x] Public Candidates Identified: [public_candidates.json](../proofs/D58_4_PUBLIC_DECISIONS/public_candidates.json)
- [x] Allowlist Updated: `tools/ewimsc/zombie_allowlist.json`
- [x] Contracts Created: 10 schemas in `tools/ewimsc/contracts/`
- [x] Zombie Count Reduced: **41 -> 31** (Confirmed via `zombie_report.json`)
- [x] Smoke Test Verified: All 10 promoted endpoints returned 200 OK.

## 1. Executive Summary
Successfully reclassified 10 "Unknown Zombie" endpoints to `PUBLIC_PRODUCT`. These endpoints are read-only (GET), artifact-backed (Law of the Lens), and verified to return 200 OK. JSON Schemas have been created for each to enforce the `FallbackEnvelope` structure (D58.1).

## 2. Promoted Scope (Batch #2)
| Endpoint | Method | Artifact/Source | Status |
| :--- | :--- | :--- | :--- |
| `/agms/summary` | GET | `agms_weekly_summary.json` | PUBLIC |
| `/agms/thresholds` | GET | `agms_dynamic_thresholds.json` | PUBLIC |
| `/efficacy` | GET | `efficacy_report.json` | PUBLIC |
| `/economic_calendar` | GET | `economic_calendar.json` | PUBLIC |
| `/options_report` | GET | `options_report.json` | PUBLIC |
| `/sunday_setup` | GET | `sunday_setup.json` | PUBLIC |
| `/overlay_live` | GET | `overlay_status.json` | PUBLIC |
| `/voice_state` | GET | `voice_state.json` | PUBLIC |
| `/on_demand/context` | GET | *Computed Cache* | PUBLIC |
| `/os/state_snapshot` | GET | `os_state.json` | PUBLIC |

## 3. Evidence
- **Promotion Decision**: [public_promotion_report.md](../proofs/D58_4_PUBLIC_DECISIONS/public_promotion_report.md)
- **Zombie Report**: [zombie_report.json](../proofs/D57_5_ZOMBIE_TRIAGE/zombie_report.json)
- **Wiring Verification**: [wiring_smoke_report.json](../proofs/D58_3_UNKNOWN_WIRING/wiring_smoke_report.json)

## Pending Closure Hook
- Resolved Pending Items:
  - None (Legacy Seal Retrofit)
- New Pending Items:
  - None

SEALED_BY: ANTIGRAVITY
DATE: 2026-02-06
