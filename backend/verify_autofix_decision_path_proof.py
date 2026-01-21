import json
import shutil
import sys
import os
from pathlib import Path
from datetime import datetime

# Add root to sys.path
sys.path.append(os.getcwd())

from backend.os_ops.autofix_tier1 import AutoFixTier1, OS_DIR, OUTPUTS_DIR, DECISION_PATH_PATH

PROOF_PATH = OUTPUTS_DIR / "proofs/day_42/day_42_10_autofix_decision_path_proof.json"

def run_test_scenario(name, setup_fn, expected_status, expected_outcome_check):
    print(f"\n--- Scenario: {name} ---")
    if setup_fn:
        setup_fn()
    
    # Run Engine
    result = AutoFixTier1.run_from_plan()
    
    # Read Artifact
    if not DECISION_PATH_PATH.exists():
        print(f"❌ FAIL: Decision path artifact missing.")
        return False
        
    with open(DECISION_PATH_PATH, "r") as f:
        dpath = json.load(f)
        
    print(f"Overall Status: {dpath['overall_status']} (Expected: {expected_status})")
    
    # Outcome Check
    if dpath['overall_status'] != expected_status:
        print("❌ FAIL: Status Mismatch")
        return False
        
    if expected_outcome_check and not expected_outcome_check(dpath):
         print("❌ FAIL: Outcome Check Failed")
         return False

    print("✅ PASS")
    return dpath

def clean_env():
    # Remove plan & artifacts
    if DECISION_PATH_PATH.exists(): DECISION_PATH_PATH.unlink()
    plan_path = OS_DIR / "os_autofix_plan.json"
    if plan_path.exists(): plan_path.unlink()
    test_target = OUTPUTS_DIR / "os/test_decision.json"
    if test_target.exists(): test_target.unlink()

def main():
    print("Verifying AutoFix Decision Path (D42.10)...")
    clean_env()
    
    proof_data = {
        "timestamp_utc": datetime.utcnow().isoformat(),
        "scenarios": []
    }
    
    # 1. Missing Plan -> NO_OP (with artifact)
    dpath = run_test_scenario(
        name="Missing Plan",
        setup_fn=None,
        expected_status="NO_OP",
        expected_outcome_check=lambda d: len(d['actions']) == 0
    )
    proof_data['scenarios'].append({"name": "MISSING_PLAN", "result": "PASS" if dpath else "FAIL", "artifact_status": dpath['overall_status'] if dpath else "MISSING"})

    # 2. Valid Success
    def setup_valid():
        clean_env()
        plan = {
            "plan_id": "TEST_DECISION_SUCCESS",
            "timestamp_utc": datetime.utcnow().isoformat(),
            "trigger_context": "TEST",
            "actions": [
                {
                    "action_code": "REGENERATE_MISSING_ARTIFACT",
                    "target": "outputs/os/test_decision.json",
                    "description": "Test Regen",
                    "reversible": True,
                    "risk_tier": "TIER_0",
                    "parameters": {"default_content": "ok"}
                }
            ]
        }
        with open(OS_DIR / "os_autofix_plan.json", "w") as f:
            json.dump(plan, f)
            
    dpath = run_test_scenario(
        name="Valid Success",
        setup_fn=setup_valid,
        expected_status="SUCCESS",
        expected_outcome_check=lambda d: d['actions'][0]['outcome'] == "EXECUTED" and d['actions'][0]['evaluation']['allowlisted'] == True
    )
    proof_data['scenarios'].append({"name": "VALID_SUCCESS", "result": "PASS" if dpath else "FAIL", "artifact_status": dpath['overall_status'] if dpath else "MISSING"})

    # 3. Blocked (Path)
    def setup_blocked():
        clean_env()
        plan = {
            "plan_id": "TEST_DECISION_BLOCKED",
            "timestamp_utc": datetime.utcnow().isoformat(),
            "trigger_context": "TEST",
            "actions": [
                {
                    "action_code": "REGENERATE_MISSING_ARTIFACT",
                    "target": "../evil_path.json",
                    "description": "Test Blocked",
                    "reversible": True,
                    "risk_tier": "TIER_0",
                    "parameters": {"default_content": "ok"}
                }
            ]
        }
        with open(OS_DIR / "os_autofix_plan.json", "w") as f:
            json.dump(plan, f)

    dpath = run_test_scenario(
        name="Blocked Path",
        setup_fn=setup_blocked,
        expected_status="FAILED", # Engine returns FAILED for path traversal exceptions currently
        expected_outcome_check=lambda d: d['actions'][0]['outcome'] == "BLOCKED" and d['actions'][0]['evaluation']['path_allowed'] == False
    )
    proof_data['scenarios'].append({"name": "BLOCKED_PATH", "result": "PASS" if dpath else "FAIL", "artifact_status": dpath['overall_status'] if dpath else "MISSING"})

    # 4. Rejected (Tier)
    def setup_rejected():
        clean_env()
        plan = {
            "plan_id": "TEST_DECISION_REJECTED",
            "timestamp_utc": datetime.utcnow().isoformat(),
            "trigger_context": "TEST",
            "actions": [
                {
                    "action_code": "REGENERATE_MISSING_ARTIFACT",
                    "target": "outputs/os/test.json",
                    "description": "Test Rejected",
                    "reversible": True,
                    "risk_tier": "TIER_2", # Bad tier
                    "parameters": {"default_content": "ok"}
                }
            ]
        }
        with open(OS_DIR / "os_autofix_plan.json", "w") as f:
            json.dump(plan, f)

    dpath = run_test_scenario(
        name="Rejected Tier",
        setup_fn=setup_rejected,
        expected_status="PARTIAL", 
        expected_outcome_check=lambda d: d['actions'][0]['outcome'] == "REJECTED" and d['actions'][0]['evaluation']['tier_allowed'] == False
    )
    proof_data['scenarios'].append({"name": "REJECTED_TIER", "result": "PASS" if dpath else "FAIL", "artifact_status": dpath['overall_status'] if dpath else "MISSING"})

    # Write Proof
    PROOF_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(PROOF_PATH, "w") as f:
        json.dump(proof_data, f, indent=2)
        
    print("\n🏁 Verification Complete. Proof generated.")

if __name__ == "__main__":
    main()
