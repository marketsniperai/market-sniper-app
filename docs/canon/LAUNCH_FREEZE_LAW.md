# LAUNCH FREEZE LAW (Day 30.1)

**Authority:** SUPREME (Launch Control)
**Status:** ACTIVE

## 1. Definition of "Core OS"
The "Core OS" represents the autonomous nervous system of MarketSniper. Modification of these components carries existential risk.

**Core OS includes:**
1.  **Autopilot Policy**: The decision engine (`autopilot_policy_engine.py`, `os_autopilot_policy.json`).
2.  **The Surgeon**: Runtime Self-Repair logic (`shadow_repair.py`).
3.  **Playbook Registry**: The library of allowed actions (`os_playbooks.yml`, `autofix_control_plane.py`).
4.  **Module Registry**: The system map (`os_registry.json`).
5.  **Pipeline Controller**: The data flow orchestrator (`pipeline_controller.py`).
6.  **Core Gates**: The safety barriers (`core_gates.py`).
7.  **War Room**: The observability plane (`war_room.py`).

## 2. The Law of Freeze
**"No Core OS component may be modified without a specific, approved Release Protocol."**

Any modification to Core OS requires:
1.  **Playbook**: A clear plan (Implementation Plan).
2.  **Checklist**: Mandatory adherence to `RELEASE_CHECKLIST.md`.
3.  **Verification**: Automated proof of safety (`verify_*.py`).
4.  **Seal**: A cryptographic sign-off (`SEAL_*.md`).

## 3. The Law of Kill Switches
The system must possess absolute "analog" overrides (Kill Switches) that function logically above the AI's cognitive layer.
- **AUTOPILOT_ENABLED**: Logic gate for *any* autonomous action.
- **SURGEON_RUNTIME_ENABLED**: Specific gate for runtime file modification.
- **PIPELINE_RUN_ENABLED**: Master valve for data processing.
- **FOUNDER_OVERRIDE**: Absolute right of the human pilot to bypass all gates.

## 4. Automation Enforcement
This law is enforced by code (`freeze_enforcer.py`). The system shall refuse to SEAL or Deploy if the Core OS definition is violated or if Kill Switches are missing.
