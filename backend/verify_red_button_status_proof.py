import json
import sys
import os
from pathlib import Path
from datetime import datetime, timezone

# Add root to sys.path
sys.path.append(os.getcwd())

from backend.os_ops.red_button_reader import RedButtonReader, RED_BUTTON_ARTIFACT_PATH

PROOF_PATH = Path("outputs/proofs/day_42/day_42_06_red_button_status_proof.json")

def setup_artifact(data):
    RED_BUTTON_ARTIFACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(RED_BUTTON_ARTIFACT_PATH, "w") as f:
        json.dump(data, f)

def clean_env():
    if RED_BUTTON_ARTIFACT_PATH.exists():
        RED_BUTTON_ARTIFACT_PATH.unlink()

def main():
    print("Verifying Red Button Status (D42.06)...")
    clean_env()
    
    proof_data = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "scenarios": []
    }
    
    # 1. Missing Artifact -> UNAVAILABLE
    print("\n--- Scenario: Missing Artifact ---")
    clean_env()
    snapshot = RedButtonReader.get_snapshot()
    if snapshot is None:
        print("✅ PASS: Snapshot is None as expected.")
        proof_data["scenarios"].append({"name": "MISSING_ARTIFACT", "result": "PASS"})
    else:
        print(f"❌ FAIL: Expected None, got {snapshot}")
        proof_data["scenarios"].append({"name": "MISSING_ARTIFACT", "result": "FAIL"})

    # 2. Valid Snapshot
    print("\n--- Scenario: Valid Snapshot ---")
    valid_data = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "available": True,
        "founder_required": True,
        "capabilities": ["TRIGGER_PIPELINE", "MISFIRE_AUTOHEAL"],
        "last_run": {
            "run_id": "RUN_789",
            "action": "TRIGGER_PIPELINE",
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "status": "SUCCESS",
            "notes": "Manually triggered"
        }
    }
    setup_artifact(valid_data)
    
    snapshot = RedButtonReader.get_snapshot()
    if snapshot and len(snapshot.capabilities) == 2 and snapshot.last_run.status == "SUCCESS":
        print("✅ PASS: Correctly read valid snapshot.")
        proof_data["scenarios"].append({"name": "VALID_SNAPSHOT", "result": "PASS"})
    else:
        print(f"❌ FAIL: Failed to read valid snapshot. Got {snapshot}")
        proof_data["scenarios"].append({"name": "VALID_SNAPSHOT", "result": "FAIL"})
        
    # 3. Invalid Data (Schema Violation)
    print("\n--- Scenario: Invalid Data ---")
    invalid_data = valid_data.copy()
    del invalid_data["capabilities"] # Missing required field
    setup_artifact(invalid_data)
    
    snapshot = RedButtonReader.get_snapshot()
    if snapshot is None:
        print("✅ PASS: Gracefully handled invalid data (returned None).")
        proof_data["scenarios"].append({"name": "INVALID_DATA", "result": "PASS"})
    else:
        print(f"❌ FAIL: Should have failed validation but got {snapshot}")
        proof_data["scenarios"].append({"name": "INVALID_DATA", "result": "FAIL"})

    # Write Proof
    PROOF_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(PROOF_PATH, "w") as f:
        json.dump(proof_data, f, indent=2)
    
    print("\n🏁 Verification Complete.")
    clean_env()

if __name__ == "__main__":
    main()
