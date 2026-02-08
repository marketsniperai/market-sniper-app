# D56.AUDIT.CHUNK_03 — CLAIM LIST (D21-D30)

**Chunk:** D21 - D30
**Status:** DRAFT

| Claim ID | Seal / Milestone | Primary Assertions | Expected Evidence | Status |
| :--- | :--- | :--- | :--- | :--- |
| **D21.AGMS.INTEL** | `SEAL_DAY_21_AGMS_INTELLIGENCE_SHADOW_MODE` | AGMS Intelligence Engine (Analysis). | Code: `backend/os_intel/agms_intelligence.py` | PENDING |
| **D22.AGMS.REC** | `SEAL_DAY_22_AGMS_SHADOW_RECOMMENDER...` | AGMS Shadow Recommender. | Code: `backend/os_intel/agms_shadow_recommender.py` | PENDING |
| **D23.PILOT.HO** | `SEAL_DAY_23_AUTOPILOT_HANDOFF...` | Autopilot Handoff Engine (HMAC). | Code: `backend/os_intel/agms_autopilot_handoff.py` | PENDING |
| **D24.THRESH** | `SEAL_DAY_24_DYNAMIC_THRESHOLDS...` | Dynamic Thresholds Logic. | Code: `backend/os_intel/agms_dynamic_thresholds.py` | PENDING |
| **D25.BANDS** | `SEAL_DAY_25_CONFIDENCE_STABILITY_BANDS` | Confidence Stability Bands. | Code: `backend/os_intel/agms_stability_bands.py` | PENDING |
| **D26.REGISTRY** | `SEAL_DAY_26_MODULE_REGISTRY...` | Registry Enforcer & JSON. | Code: `backend/module_registry_enforcer.py` | PENDING |
| **D27.REFACTOR** | `SEAL_DAY_27_MODULAR_REFACTOR` | Physical split (Ops vs Intel). | Dir: `backend/os_ops`, `backend/os_intel` | PENDING |
| **D28.POLICY** | `SEAL_DAY_28_AUTOPILOT_POLICY_V1` | Autopilot Policy Engine. | Code: `backend/os_ops/autopilot_policy.py` | PENDING |
| **D30.FREEZE** | `SEAL_DAY_30_1_FREEZE_CORE...` | Kill Switches & Freeze Enforcer. | Code: `backend/os_ops/freeze_enforcer.py`| PENDING |
| **D30.SURGEON** | `SEAL_DAY_30_2_SURGEON_2VOTE...` | The Surgeon (Shadow Repair) with Vote Logic. | Code: `backend/os_ops/shadow_repair.py` | PENDING |
