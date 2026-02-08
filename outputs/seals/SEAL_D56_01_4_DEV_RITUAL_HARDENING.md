# SEAL: D56.01.4 — DEV RITUAL HARDENING (VERIFIED STATE MACHINE)

**Date:** 2026-02-05
**Author:** Antigravity (Agent)
**Status:** SEALED

## 1. Context
The `dev_ritual.ps1` script ("Pulse Check") had a critical flaw: it blindly assumed any listener on port 8000 was a valid backend. This allowed "session drift" where an old backend process (with a stale key) caused War Room blackouts (Frontend sending Key A, Backend expecting Key B or None).

## 2. Changes
- **Target:** `tools/dev_ritual.ps1`
- **Logic Upgrade:** "Verified State Machine"
  - **Step 1:** Resolve Key (Env -> .env.local -> Default).
  - **Step 2:** Check Port 8000.
  - **Step 3 (New):** If Port Active, **PROBE** `/lab/war_room/snapshot` with `X-Founder-Key`.
    - If 200 OK -> **SKIP** (Verified).
    - If != 200 -> **KILL** (Drift Detected).
  - **Step 4:** If Needed, Start Backend with explicit `FOUNDER_KEY` injection.
  - **Step 5 (New):** **LIVENESS LOOP** (Poll 20x for 200 OK). Exit 1 if failed.
  - **Step 6:** Launch Flutter with `--dart-define`.

## 3. Verification
### A. Safety
- **No Secrets:** Key logic reads from sourced environment or safe default. No hardcoded keys committed.
- **Fail-Safe:** Script exits non-zero if backend fails to stabilize.

### B. Hygiene
**Pre-Seal Git Status:**
```
M  .gitignore
MM PROJECT_STATE.md
M  docs/canon/OMSR_WAR_CALENDAR__35_55_DAYS.md
M  tools/dev_ritual.ps1
?? snapshot_verify.json
```

## 4. Outcome
The "Pulse Check" is now a **Hard Gate**. It is physically impossible for the dev ritual to complete successfully without a verified, key-matched backend listening on port 8000.

## Pending Closure Hook
- Resolved Pending Items:
  - None (Legacy Seal Retrofit)
- New Pending Items:
  - None
