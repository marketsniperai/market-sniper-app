# RELEASE CHECKLIST (Day 30.1)

**Authority:** CORE FREEZE LAW
**Status:** MANDATORY

## 1. Automated Verification (The Machine)
- [ ] **Core Verify Suite**: `verify_day_30_1_freeze.py` PASS
- [ ] **Artifact Presence**: All documents listed in `LAUNCH_FREEZE_LAW.md` exist.
- [ ] **Registry Enforcement**: `freeze_enforcer.py` reports ZERO violations.
- [ ] **Kill Switches**: `os_kill_switches.json` is present and valid.

## 2. Infrastructure (The Pipes)
- [ ] **Endpoint Smoke Test**: `/health_ext`, `/misfire`, `/context` respond 200.
- [ ] **Pipeline Liveness**: `misfire_report.json` is fresh.
- [ ] **Locking**: `os_lock` (if present) is < 26 hours old (or absent).

## 3. Autonomy (The Brain)
- [ ] **Policy Mode**: Confirmed in War Room (SHADOW or SAFE_AUTOPILOT).
- [ ] **Surgeon Status**: `SURGEON_RUNTIME_ENABLED` matches desired state.
- [ ] **Risk Tags**: Shadow Repair is generating tags correctly (`verify_day_28_02`).

## 4. Documentation (The Law)
- [ ] **Canon Sync**: `D31_1_CANON_SYNC_SUMMARY.md` exists.
- [ ] **Seal**: Final Seal Artifact generated.

## 5. Deployment
- [ ] **No Unsealed Core Changes**: All changes to `backend/` are sealed.
- [ ] **Founder Greenlight**: Ready for Release Candidate build.
