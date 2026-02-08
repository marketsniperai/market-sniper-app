# D58 ENDPOINT CLEANUP SEQUENCE

## Phase 1: High Risk Shield (Immediate)
**Objective:** Lock down all endpoints exposing writing capabilities, forensic data, or sensitive internal logic.
**Target State:** `LAB_INTERNAL` (Strict 403).
**Candidates:**
- `/autofix`
- `/blackbox/ledger/tail`
- `/blackbox/snapshots`
- `/blackbox/status`
- `/elite/chat`
- `/elite/reflection`
- `/elite/settings`
- `/misfire`
- `/os/state_snapshot`
- `/sunday_setup`

## Phase 2: Internal Review (Medium Risk)
**Objective:** Verify internal tools and stable artifact readers. Shield as LAB_INTERNAL unless proven product-safe.
**Candidates:**
- `/agms/handoff/ledger/tail`
- `/agms/intelligence`
- `/agms/ledger/tail`
- `/agms/shadow/ledger/tail`
- `/agms/shadow/suggestions`
- `/agms/summary`
- `/agms/thresholds`
- `/dojo/status`
- `/dojo/tail`
- `/elite/agms/recall`
- `/elite/context/status`
- `/elite/explain/status`
- `/elite/micro_briefing/open`
- `/elite/os/snapshot`
- `/elite/ritual`
- `/elite/ritual/{ritual_id}`
- `/elite/script/first_interaction`
- `/elite/state`
- `/elite/what_changed`
- `/immune/status`
- `/immune/tail`
- `/tuning/status`
- `/tuning/tail`

## Phase 3: Product Promotion (Low Risk)
**Objective:** Verify read-only safety/cost and promote to `PUBLIC_PRODUCT`.
**Candidates:**
- `/economic_calendar`
- `/efficacy`
- `/events/latest`
- `/events/latest`
- `/evidence_summary`
- `/on_demand/context`
- `/options_report`
- `/overlay_live`
- `/voice_state`