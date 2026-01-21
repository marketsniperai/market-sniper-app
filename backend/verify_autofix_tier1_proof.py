import json
import shutil
import sys
import os
from pathlib import Path
from datetime import datetime

# Add root to sys.path
sys.path.append(os.getcwd())

from backend.os_ops.autofix_tier1 import AutoFixTier1, OS_DIR, OUTPUTS_DIR

def run_test_scenario(name, setup_fn, expected_status, expected_executed, expected_skipped, expected_failed):
    print(f"\n--- Scenario: {name} ---")
    setup_fn()
    result = AutoFixTier1.run_from_plan()
    
    print(f"Result Status: {result.status} (Expected: {expected_status})")
    print(f"Executed: {result.actions_executed} (Expected: {expected_executed})")
    print(f"Skipped: {result.actions_skipped} (Expected: {expected_skipped})")
    print(f"Failed: {result.actions_failed} (Expected: {expected_failed})")
    
    if (result.status == expected_status and 
        result.actions_executed == expected_executed and 
        result.actions_skipped == expected_skipped and 
        result.actions_failed == expected_failed):
        print("✅ PASS")
    else:
        print("❌ FAIL")
        # Dump result for debug
        print(json.dumps(result.dict(), indent=2, default=str))

def clean_env():
    # Remove plan
    plan_path = OS_DIR / "os_autofix_plan.json"
    if plan_path.exists():
        plan_path.unlink()
    
    # Remove test targets
    test_target = OUTPUTS_DIR / "os/test_artifact.json"
    if test_target.exists():
        test_target.unlink()

def main():
    print("🧪 Verifying AutoFix Tier 1...")
    clean_env()
    
    # 1. Missing Plan
    run_test_scenario(
        name="Missing Plan",
        setup_fn=lambda: None,
        expected_status="NOOP",
        expected_executed=0,
        expected_skipped=0,
        expected_failed=0
    )
    
    # 2. Invalid Plan (Bad JSON)
    def setup_invalid():
        with open(OS_DIR / "os_autofix_plan.json", "w") as f:
            f.write("{ invalid json")
            
    run_test_scenario(
        name="Invalid Plan JSON",
        setup_fn=setup_invalid,
        expected_status="NOOP",
        expected_executed=0,
        expected_skipped=0,
        expected_failed=0 # Engine catches and treats as NOOP result with FAILED internal action but overall status NOOP for safety degrade
    )

    # 3. Valid Plan - Execution
    def setup_valid():
        plan = {
            "plan_id": "TEST_PLAN_01",
            "timestamp_utc": datetime.utcnow().isoformat(),
            "trigger_context": "TEST",
            "actions": [
                {
                    "action_code": "REGENERATE_MISSING_ARTIFACT",
                    "target": "outputs/os/test_artifact.json",
                    "description": "Create test file",
                    "reversible": True,
                    "risk_tier": "TIER_0",
                    "parameters": {"default_content": {"foo": "bar"}}
                }
            ]
        }
        with open(OS_DIR / "os_autofix_plan.json", "w") as f:
            json.dump(plan, f)

    run_test_scenario(
        name="Valid Plan Execution",
        setup_fn=setup_valid,
        expected_status="SUCCESS",
        expected_executed=1,
        expected_skipped=0,
        expected_failed=0
    )
    
    # Verify file created
    test_target = OUTPUTS_DIR / "os/test_artifact.json"
    if test_target.exists():
        print("✅ Artifact created")
    else:
        print("❌ Artifact NOT created")
        
    # 4. Mixed (Valid + Skipped + Failed)
    def setup_mixed():
        plan = {
            "plan_id": "TEST_PLAN_02",
            "timestamp_utc": datetime.utcnow().isoformat(),
            "trigger_context": "TEST",
            "actions": [
                {
                    # Valid
                    "action_code": "REGENERATE_MISSING_ARTIFACT",
                    "target": "outputs/os/test_artifact_2.json",
                    "description": "Create test file 2",
                    "reversible": True,
                    "risk_tier": "TIER_0",
                    "parameters": {"default_content": "success"}
                },
                {
                    # Invalid Code -> SKIP
                    "action_code": "DESTROY_WORLD",
                    "target": "outputs/os/test.json",
                    "description": "Bad code",
                    "reversible": True,
                    "risk_tier": "TIER_0" 
                },
                {
                    # Not Reversible -> SKIP
                    "action_code": "REGENERATE_MISSING_ARTIFACT",
                    "target": "outputs/os/test.json",
                    "description": "Non reversible",
                    "reversible": False,
                    "risk_tier": "TIER_0" 
                },
                 {
                    # Bad Tier -> SKIP
                    "action_code": "REGENERATE_MISSING_ARTIFACT",
                    "target": "outputs/os/test.json",
                    "description": "Tier 2",
                    "reversible": True,
                    "risk_tier": "TIER_2" 
                },
                 {
                    # Path Traversal -> FAIL (if strict) or FAIL
                     "action_code": "REGENERATE_MISSING_ARTIFACT",
                     "target": "../outside.json",
                     "description": "Path traversal",
                     "reversible": True,
                     "risk_tier": "TIER_0",
                     "parameters": {"default_content": "evil"}
                 }
            ]
        }
        with open(OS_DIR / "os_autofix_plan.json", "w") as f:
            json.dump(plan, f)

    run_test_scenario(
        name="Mixed Scenario",
        setup_fn=setup_mixed,
        expected_status="PARTIAL", # 1 success, others skipped/failed
        expected_executed=1, 
        expected_skipped=3, 
        expected_failed=1 
    )

    clean_env()
    print("\n🏁 Verification Complete")

if __name__ == "__main__":
    main()
