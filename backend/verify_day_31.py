import json
import os
import sys
import shutil
from pathlib import Path
from datetime import datetime, timezone

# Fix Path
sys.path.append(os.getcwd())

from backend.os_ops.autopilot_policy_engine import AutopilotPolicyEngine
from backend.os_ops.shadow_repair import ShadowRepair
from backend.artifacts.io import atomic_write_json, get_artifacts_root

OUTPUT_DIR = "outputs/runtime/day_31"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def reset_ledger():
    root = get_artifacts_root()
    ledger = root / "runtime/autopilot/autopilot_policy_ledger.jsonl"
    if ledger.exists():
        ledger.unlink()

def set_band(band_name):
    # Mock band for engine check
    root = get_artifacts_root()
    path = root / "runtime/agms/agms_stability_band.json"
    os.makedirs(path.parent, exist_ok=True)
    atomic_write_json(path, {"band": band_name})

def run_test(name, assertion_func):
    print(f"--- TEST: {name} ---")
    try:
        if assertion_func():
            print("PASS")
            return True
        else:
            print("FAIL")
            return False
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_deny_high_risk_patch():
    set_band("GREEN")
    # Context with HIGH_RISK
    ctx = {
        "band": "GREEN", 
        "pattern": "TEST_SURGEON_DENY", 
        "confidence_score": 0.9,
        "risk_tags": ["HIGH_RISK", "MODIFY_SOURCE"]
    }
    
    decision = AutopilotPolicyEngine.evaluate_autopilot_decision(
        context=ctx,
        playbook_id="PB-SURGEON-TEST",
        action_code="APPLY_PATCH_RUNTIME",
        founder_key_present=False
    )
    print(f"Decision: {decision['status']}, Reasons: {decision['reasons']}")
    
    if decision['status'] != "DENY": return False
    if not any("Surgeon attempted High Risk" in r for r in decision['reasons']): return False
    return True

def test_allow_runtime_safe_patch():
    reset_ledger()
    set_band("GREEN")
    # Context with LOW_RISK + RUNTIME
    ctx = {
        "band": "GREEN", 
        "pattern": "TEST_SURGEON_ALLOW", 
        "confidence_score": 0.9,
        "risk_tags": ["LOW_RISK", "TOUCHES_RUNTIME_ONLY"]
    }
    
    decision = AutopilotPolicyEngine.evaluate_autopilot_decision(
        context=ctx,
        playbook_id="PB-SURGEON-TEST-2",
        action_code="APPLY_PATCH_RUNTIME",
        founder_key_present=False
    )
    print(f"Decision: {decision['status']}")
    
    if decision['status'] != "ALLOW":
        print(f"Reasons: {decision['reasons']}")
        return False
    return True

def test_execute_surgeon_recovery():
    # 1. Propose Patch (Misfire)
    prop = ShadowRepair.propose_patch_v15(["MISSING_LIGHT_MANIFEST"])
    prop_id = prop["proposal_id"]
    
    # 2. Exec Apply
    # We call apply_proposal directly (simulating Autofix doing it after Approval)
    # The Policy check happened in test_allow_runtime_safe_patch.
    # ShadowRepair.apply_proposal has its own internal checks? Not really, it assumes caller checked safety.
    # It does check path safety.
    
    res = ShadowRepair.apply_proposal(prop_id)
    print(f"Apply Result: {res}")
    
    if not res["success"]: 
         print(f"FAILED TO APPLY: {res.get('error')}")
         return False
    
    # Verify file exists
    root = get_artifacts_root()
    target = root / "outputs/light/run_manifest.json"
    if not target.exists(): return False
    
    return True

def main():
    failures = []
    
    if not run_test("Deny High Risk Surgeon", test_deny_high_risk_patch): failures.append("Deny High Risk")
    if not run_test("Allow Safe Surgeon", test_allow_runtime_safe_patch): failures.append("Allow Safe")
    if not run_test("Execute Surgeon Apply", test_execute_surgeon_recovery): failures.append("Exec Apply")
    
    if failures:
        print(f"FAILURES: {failures}")
        sys.exit(1)
    else:
        print("ALL TESTS PASSED")
        sys.exit(0)

if __name__ == "__main__":
    main()
