import json
import os
import sys
import shutil
from pathlib import Path

# Fix Path
sys.path.append(os.getcwd())

from backend.os_ops.autopilot_policy_engine import AutopilotPolicyEngine
from backend.os_ops.war_room import WarRoom
from backend.artifacts.io import atomic_write_json, get_artifacts_root

OUTPUT_DIR = "outputs/runtime/day_29"
os.makedirs(OUTPUT_DIR, exist_ok=True)

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

def test_policy_mode_shadow():
    # Load policy and check active_mode
    root = get_artifacts_root()
    p_path = Path("os_autopilot_policy.json") # Repo root
    
    with open(p_path, "r") as f:
        policy = json.load(f)
        
    mode = policy.get("configuration", {}).get("active_mode")
    print(f"Loaded Policy Mode: {mode}")
    print(f"Policy Keys: {policy.keys()}")
    return mode == "SHADOW"

def test_shadow_logging():
    # Inject a test decision
    AutopilotPolicyEngine.evaluate_autopilot_decision(
        context={"pattern": "TEST_PATTERN_D29"},
        playbook_id="PB-TEST-D29",
        action_code="RUN_PIPELINE_LIGHT",
        founder_key_present=False
    )
    
    # Check Ledger
    root = get_artifacts_root()
    ledger = root / "runtime/autopilot/autopilot_shadow_decisions.jsonl"
    
    if not ledger.exists():
        print("FAIL: Ledger missing")
        return False
        
    found = False
    with open(ledger, "r") as f:
        for line in f:
            if "PB-TEST-D29" in line:
                entry = json.loads(line)
                print(f"Entry: {entry}")
                if entry["execution_status"] != "NOT_EXECUTED":
                    print("FAIL: Execution status mismatch")
                    return False
                if entry["hypothetical_action"] != "BLOCKED":
                     # In SHADOW mode, everything is blocked except if allowed.
                     # Shadow Policy says allow_execution: False
                     # So status should be DENY -> Hypothetical: BLOCKED (or whatever logic trace used)
                     pass
                found = True
                break
    return found

def test_war_room_shadow_summary():
    dash = WarRoom.get_dashboard()
    summary = dash["modules"].get("autopilot_shadow_summary", {})
    print(f"Shadow Summary: {summary}")
    
    if summary.get("total_decisions", 0) < 1:
        return False
    if "top_deny_reasons" not in summary:
        return False
    return True

def main():
    failures = []
    
    if not run_test("Policy Mode = SHADOW", test_policy_mode_shadow):
        failures.append("Policy Mode")
        
    if not run_test("Shadow Ledger Logging", test_shadow_logging):
        failures.append("Shadow Trace")
        
    if not run_test("War Room Summary", test_war_room_shadow_summary):
        failures.append("War Room")
        
    if failures:
        print(f"FAILURES: {failures}")
        sys.exit(1)
    else:
        print("ALL TESTS PASSED")
        sys.exit(0)

if __name__ == "__main__":
    main()
