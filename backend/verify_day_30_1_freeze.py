import json
import os
import sys
from pathlib import Path
sys.path.append(os.getcwd())

from backend.os_ops.freeze_enforcer import FreezeEnforcer
from backend.os_ops.shadow_repair import ShadowRepair
from backend.os_ops.autopilot_policy_engine import AutopilotPolicyEngine
from backend.artifacts.io import atomic_write_json

OUTPUT_DIR = "outputs/runtime/day_30_1"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def reset_ledger():
    from backend.artifacts.io import get_artifacts_root
    root = get_artifacts_root()
    ledger = root / "runtime/autopilot/autopilot_policy_ledger.jsonl"
    if ledger.exists():
        ledger.unlink()

def run_verify():
    print("--- VERIFY: Day 30.1 Core OS Freeze ---")
    reset_ledger()
    
    # 1. Run Enforcer
    print("1. Running Enforcer...")
    report = FreezeEnforcer.enforce()
    with open(f"{OUTPUT_DIR}/day_30_1_enforcer_report.json", "w") as f:
        json.dump(report, f, indent=2)
        
    if report["status"] != "PASS":
        print(f"FAIL: Enforcer reported violations: {report}")
        return False
    print("PASS: Enforcer")
    
    # 2. Dump Kill Switches
    print("2. Dumping Kill Switches...")
    ks = report.get("kill_switch_status", {})
    with open(f"{OUTPUT_DIR}/day_30_1_kill_switches_dump.json", "w") as f:
        json.dump(ks, f, indent=2)
    print(f"PASS: Switches: {ks}")
    
    # 3. Test Surgeon Runtime Block (Kill Switch)
    print("3. Testing Surgeon Kill Switch...")
    # Temporarily DISABLING Surgeon in config to test the block
    original_config = None
    with open("os_kill_switches.json", "r") as f:
        original_config = json.load(f)
        
    try:
        # Disable Surgeon
        # Use deep copy or manual reconstruction to avoid side effects
        mod_config = json.loads(json.dumps(original_config)) # Deep copy hack
        mod_config["switches"]["SURGEON_RUNTIME_ENABLED"] = False
        
        # Use standard write to ensure it works in CWD
        with open("os_kill_switches.json", "w") as f:
            json.dump(mod_config, f, indent=4)
            
        print("DEBUG: Wrote Kill Switch Config with SURGEON_RUNTIME_ENABLED=False")
        
        # Verify it stuck
        with open("os_kill_switches.json", "r") as f:
             check = json.load(f)
             print(f"DEBUG: Verify Readback: {check['switches']['SURGEON_RUNTIME_ENABLED']}")
        
        # Test 1: Policy Allowlist Deny by Kill Switch?
        # Create a mock context
        ctx = {"band": "GREEN", "risk_tags": ["LOW_RISK", "TOUCHES_RUNTIME_ONLY"]}
        # Try Policy
        decision = AutopilotPolicyEngine.evaluate_autopilot_decision(ctx, "PB-TEST", "APPLY_PATCH_RUNTIME")
        
        if decision["status"] != "DENY":
            print(f"FAIL: Policy allowed Surgeon despite Kill Switch OFF. Reasons: {decision.get('reasons')}")
            return False
            
        if "KILL_SWITCH: SURGEON_RUNTIME_ENABLED is FALSE" not in decision["reasons"][0]:
             print(f"FAIL: Policy denied but wrong reason: {decision.get('reasons')}")
             return False
             
        # Test 2: Shadow Repair Direct Call Deny
        res = ShadowRepair.apply_proposal("mock-id")
        if res["success"]:
             print("FAIL: ShadowRepair.apply_proposal succeeded despite Kill Switch OFF")
             return False
        if "KILL_SWITCH" not in res.get("error", ""):
             print(f"FAIL: ShadowRepair error mismatch: {res.get('error')}")
             return False
             
        print("PASS: Surgeon Blocked by Kill Switch")
        
    finally:
        # Restore Config
        if original_config:
            atomic_write_json("os_kill_switches.json", original_config)
            
    # 4. Final Success Artifact
    result = {"status": "PASS", "timestamp": "2026-02-28T12:00:00Z"}
    with open(f"{OUTPUT_DIR}/day_30_1_verify.json", "w") as f:
        json.dump(result, f)
        
    return True

if __name__ == "__main__":
    if run_verify():
        print("ALL TESTS PASSED")
        sys.exit(0)
    else:
        print("TESTS FAILED")
        sys.exit(1)
