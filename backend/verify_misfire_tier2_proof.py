import json
import sys
import os
from pathlib import Path
from datetime import datetime, timezone

# Add root to sys.path
sys.path.append(os.getcwd())

from backend.os_ops.misfire_tier2_reader import MisfireTier2Reader, MISFIRE_TIER2_ARTIFACT_PATH

PROOF_PATH = Path("outputs/proofs/day_42/day_42_05_misfire_tier2_surface_proof.json")

def setup_artifact(data):
    MISFIRE_TIER2_ARTIFACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(MISFIRE_TIER2_ARTIFACT_PATH, "w") as f:
        json.dump(data, f)

def clean_env():
    if MISFIRE_TIER2_ARTIFACT_PATH.exists():
        MISFIRE_TIER2_ARTIFACT_PATH.unlink()

def main():
    print("Verifying Misfire Tier 2 Visibility (D42.05)...")
    clean_env()
    
    proof_data = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "scenarios": []
    }
    
    # 1. Missing Artifact -> UNAVAILABLE
    print("\n--- Scenario: Missing Artifact ---")
    clean_env()
    snapshot = MisfireTier2Reader.get_snapshot()
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
        "incident_id": "INC-001",
        "detected_by": "MisfireMonitor",
        "escalation_policy": "POLICY_DEFAULT",
        "steps": [
            {
                "step_id": "RETRY_PIPELINE",
                "description": "Retry pipeline run",
                "attempted": True,
                "permitted": True,
                "gate_reason": None,
                "result": "SUCCESS",
                "timestamp_utc": datetime.now(timezone.utc).isoformat()
            }
        ],
        "final_outcome": "RESOLVED",
        "action_taken": "PIPELINE_RUN",
        "notes": "Resolved automatically"
    }
    setup_artifact(valid_data)
    
    snapshot = MisfireTier2Reader.get_snapshot()
    if snapshot and snapshot.incident_id == "INC-001" and len(snapshot.steps) == 1:
        print("✅ PASS: Correctly read valid snapshot.")
        proof_data["scenarios"].append({"name": "VALID_SNAPSHOT", "result": "PASS"})
    else:
        print(f"❌ FAIL: Failed to read valid snapshot. Got {snapshot}")
        proof_data["scenarios"].append({"name": "VALID_SNAPSHOT", "result": "FAIL"})
        
    # 3. Invalid Data (Schema Violation)
    print("\n--- Scenario: Invalid Data ---")
    invalid_data = valid_data.copy()
    del invalid_data["incident_id"] # Missing required field
    setup_artifact(invalid_data)
    
    snapshot = MisfireTier2Reader.get_snapshot()
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
