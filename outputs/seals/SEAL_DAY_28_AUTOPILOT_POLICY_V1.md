# SEAL: DAY 28 - AUTOPILOT POLICY v1 (AUTONOMY DIAL)

> **"AGMS Thinks. Autofix Acts. The Policy Decides."**

## 1. Executive Summary
Day 28 establishes the "Autonomy Dial" (Autopilot Policy v1), a strict governance layer that controls when Autofix may execute actions handed off by AGMS. This policy ensures that "Thinking" (AGMS) never directly causes "Action" (Autofix) without passing through a configurable, evidence-based policy gate.

## 2. Implementation Truth
*   **Canon Policy**: `os_autopilot_policy.json` (Modes: OFF, SHADOW, SAFE_AUTOPILOT, FULL_AUTOPILOT).
*   **Engine**: `backend/os_ops/autopilot_policy_engine.py` (Evaluates Mode + Band + Limits + Evidence).
*   **Integration**: `backend/os_ops/autofix_control_plane.py` (Gated at `execute_from_handoff`).
*   **Visibility**: War Room Dashboard now reflects Policy Status.

## 3. Verification Results
| Test Case | Mode | Band | Expected | Actual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline Shadow** | SHADOW | GREEN | DENY | DENY | PASS |
| **Safe Green** | SAFE_AUTOPILOT | GREEN | ALLOW | ALLOW | PASS |
| **Orange Guard** | SAFE_AUTOPILOT | ORANGE | DENY | DENY | PASS |
| **Rate Limit** | SAFE_AUTOPILOT | GREEN | DENY (2nd/hr) | DENY | PASS |

## 4. Titanium Law Reaffirmation
*   **AGMS** remains Read-Only (Intelligence).
*   **Autofix** remains the only Executor.
*   **Policy Engine** is the Gatekeeper.
*   **Founder Key** retains ultimate override authority (via Policy Config).

## 5. Next Steps
*   **Day 29**: Observation of Shadow Mode decisions in War Room.
*   **Future**: Enable "SAFE_AUTOPILOT" after 24h of stable Shadow observation.

## 6. Sign-off
*   **Operator**: Antigravity
*   **Date**: 2026-01-14
*   **Status**: SEALED
