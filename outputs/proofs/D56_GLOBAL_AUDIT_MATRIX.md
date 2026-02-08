# D56.AUDIT.GLOBAL — AUDIT MATRIX

**Date:** 2026-02-05
**Auditor:** Antigravity

## Summary Counts
| Status | Count | Description |
| :--- | :--- | :--- |
| **GREEN** | 0 | Verified Operational (Reach + Runtime) |
| **YELLOW** | 0 | Wired but Unverified (No runtime proof) |
| **RED** | 0 | Broken / Missing / Config Failure |
| **STUB** | 0 | Artifact-First Stub (No real engine) |
| **GHOST** | 0 | Code exists, no wiring / unreachable |

---

## 1. Backend Route Inventory (API Server)

| Route | Method | Module/Engine | Gating/Shield | Status | Evidence |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `/lab/healthz` | GET | Probe (Shield Bypass) | OPEN | PENDING | |
| `/lab/readyz` | GET | Probe (Shield Bypass) | OPEN | PENDING | |
| `/lab/run_pipeline` | POST | Pipeline Controller | Founder | PENDING | |
| `/lab/misfire_autoheal` | POST | Misfire Monitor | Founder | PENDING | |
| `/health_ext` | GET | Health/Manifest | Public | PENDING | |
| `/dashboard` | GET | Dashboard | Public | PENDING | |
| `/context` | GET | Context | Public | PENDING | |
| `/efficacy` | GET | Efficacy | Public | PENDING | |
| `/misfire` | GET | Misfire Monitor | Public | PENDING | |
| `/options_context` | GET | Options Engine | Public | PENDING | |
| `/economic_calendar` | GET | Economic Calendar | Public | PENDING | |
| `/macro_context` | GET | Macro Engine | Public | PENDING | |
| `/evidence_summary` | GET | Evidence Engine | Public | PENDING | |
| `/overlay_live` | GET | Overlay Live | Public | PENDING | |
| `/voice_state` | GET | Voice MVP | Public | PENDING | |
| `/news_digest` | GET | News Engine | Public | PENDING | |
| `/autofix` | GET | AutoFix Control | Public | PENDING | |
| `/lab/autofix/execute` | POST | AutoFix Control | Founder | PENDING | |
| `/lab/os/self_heal/housekeeper/status` | GET | Housekeeper | Founder | PENDING | |
| `/lab/os/self_heal/housekeeper/run` | POST | Housekeeper | Founder | PENDING | |
| `/lab/os/housekeeper/run` | POST | Housekeeper (D56) | Founder | PENDING | Possible Duplicate |
| `/lab/os/housekeeper/status` | GET | Housekeeper (D56) | Founder | PENDING | Possible Duplicate |
| `/lab/os/iron/status` | GET | Iron OS | Founder | PENDING | |
| `/lab/replay/day` | POST | Replay Engine | Founder | STUB | Code explicitly returns UNAVAILABLE |
| `/lab/os/rollback` | POST | Rollback Engine | Founder | STUB | Code explicitly returns UNAVAILABLE |
| `/lab/war_room` | GET | War Room | Founder | PENDING | |

## 2. OS Engines Operational Status

| Engine | Claimed Status | Code Exists? | Wired? | Runnable? | Verified? | Verdict |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Housekeeper** | Active | YES | YES | PENDING | PENDING | PENDING |
| **Misfire Monitor** | Active | YES | YES | PENDING | PENDING | PENDING |
| **AutoFix** | Active | YES | YES | PENDING | PENDING | PENDING |
| **Iron OS** | Active | YES | YES | PENDING | PENDING | PENDING |
| **Replay** | Stub | YES | YES | NO | NO | STUB |
| **Rollback** | Stub | YES | YES | NO | NO | STUB |
| **Universe** | Unknown | PENDING | PENDING | PENDING | PENDING | PENDING |

## 3. Artifact Origin Map
*To be populated*

## 4. Truth Corrections & Discrepancies
- **Housekeeper Duplicate Routes**: `/lab/os/self_heal/housekeeper/run` AND `/lab/os/housekeeper/run`. Potential confusion.
- **Replay/Rollback**: Explicitly stubbed in code, should be marked as STUB in official docs if not already.

