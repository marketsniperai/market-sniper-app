import json
import os
import sys
import shutil
from pathlib import Path

# Fix Path for Imports
sys.path.append(os.getcwd())

from backend.os_ops.autopilot_policy_engine import AutopilotPolicyEngine
from backend.artifacts.io import atomic_write_json, get_artifacts_root

# Setup Test Artifacts
OUTPUT_DIR = "outputs/runtime/day_28"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def setup_test_env(mode="SHADOW", band="GREEN", keep_ledger=False):
    """
    Writes a temporary policy and band for testing.
    """
    root = get_artifacts_root()
    
    # 1. Write Policy
    policy = {
      "configuration": {
        "active_mode": mode,
        "founder_overrides": {"allow_safe_autopilot_with_key": True}
      },
      "modes": {
        "OFF": {"allow_execution": False},
        "SHADOW": {"allow_execution": False},
        "SAFE_AUTOPILOT": {
          "allow_execution": True,
          "required_band": ["GREEN"],
          "require_evidence": True
        }
      },
      "limits": {
        "max_actions_per_day": 2,
        "max_actions_per_hour": 1,
        "max_consecutive_same_playbook": 1
      },
      "allowlist": ["RUN_PIPELINE_LIGHT", "RUN_PIPELINE_FULL"],
      "required_evidence_rules": {"agms_suggestion_must_exist": True}
    }
    with open("os_autopilot_policy.json", "w") as f:
        json.dump(policy, f)
        
    # 2. Write Band
    atomic_write_json("runtime/agms/agms_stability_band.json", {"band": band})
    
    # 3. Clear Ledger (for clean limit tests)
    ledger = root / "runtime/autopilot/autopilot_policy_ledger.jsonl"
    if not keep_ledger and ledger.exists():
        os.remove(ledger)

def run_test(name, mode, band, expected_status, founder_key=False, action="RUN_PIPELINE_LIGHT", playbook="PB-TEST", keep_ledger=False):
    print(f"--- TEST: {name} [Mode={mode}, Band={band}, Key={founder_key}] ---")
    setup_test_env(mode, band, keep_ledger=keep_ledger)
    
    decision = AutopilotPolicyEngine.evaluate_autopilot_decision(
        context={},
        playbook_id=playbook,
        action_code=action,
        founder_key_present=founder_key
    )
    
    print(f"Decision: {decision['status']}")
    print(f"Reasons: {decision['reasons']}")
    
    with open(f"{OUTPUT_DIR}/day_28_{name}.txt", "w") as f:
        f.write(json.dumps(decision, indent=2))
        
    if decision["status"] != expected_status:
        print("FAIL")
        return False
    return True

def main():
    failures = []
    
    # Test 1: Baseline Shadow (DENY)
    if not run_test("baseline_shadow", "SHADOW", "GREEN", "DENY"):
        failures.append("Baseline Shadow")
        
    # Test 2: Safe Autopilot Green (ALLOW)
    # Using a fake action that is in allowlist
    if not run_test("allow_green_safe", "SAFE_AUTOPILOT", "GREEN", "ALLOW"):
        failures.append("Safe Autopilot Green")

    # Test 3: Safe Autopilot Orange (DENY)
    if not run_test("deny_orange", "SAFE_AUTOPILOT", "ORANGE", "DENY"):
        failures.append("Safe Autopilot Orange")
        
    # Test 4: Rate Limit (Second in Hour DENY)
    print("--- TEST: Rate Limit ---")
    # First Allow
    run_test("rate_limit_1", "SAFE_AUTOPILOT", "GREEN", "ALLOW") 
    # Second Deny (same hour) - KEEP LEDGER
    if not run_test("rate_limit_denied", "SAFE_AUTOPILOT", "GREEN", "DENY", playbook="PB-TEST-2", keep_ledger=True):
        failures.append("Rate Limit Check")
        
    # Test 5: Allowlist Fail
    print("--- TEST: Allowlist Fail ---")
    if not run_test("allowlist_fail", "SAFE_AUTOPILOT", "GREEN", "DENY", action="DESTROY_WORLD"):
        failures.append("Allowlist Fail")
        
    # Restore Default Policy (Shadow)
    setup_test_env("SHADOW", "GREEN")

    if failures:
        print(f"FAILURES: {failures}")
        sys.exit(1)
    else:
        print("ALL TESTS PASSED")
        sys.exit(0)

if __name__ == "__main__":
    main()
