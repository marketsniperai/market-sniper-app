import json
import sys
import os
from pathlib import Path
from datetime import datetime, timezone

# Add root to sys.path
sys.path.append(os.getcwd())

from backend.os_ops.self_heal_what_changed_reader import SelfHealWhatChangedReader, WHAT_CHANGED_ARTIFACT_PATH

PROOF_PATH = Path("outputs/proofs/day_42/day_42_13_self_heal_what_changed_proof.json")

def setup_artifact(data):
    WHAT_CHANGED_ARTIFACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(WHAT_CHANGED_ARTIFACT_PATH, "w") as f:
        json.dump(data, f)

def clean_env():
    if WHAT_CHANGED_ARTIFACT_PATH.exists():
        WHAT_CHANGED_ARTIFACT_PATH.unlink()

def main():
    print("Verifying Self-Heal What Changed (D42.13)...")
    clean_env()
    
    proof_data = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "scenarios": []
    }
    
    # 1. Missing Artifact -> UNAVAILABLE
    print("\n--- Scenario: Missing Artifact ---")
    clean_env()
    snapshot = SelfHealWhatChangedReader.get_snapshot()
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
        "run_id": "RUN_123",
        "summary": "Fixed broken manifesto",
        "artifacts_updated": [
            {
                "path": "c:/MSR/MarketSniperRepo/iron_manifest.json",
                "change_type": "UPDATED",
                "before_hash": "abc",
                "after_hash": "def"
            }
        ],
        "state_transition": {
            "from_state": "LOCKED",
            "to_state": "NOMINAL",
            "unlocked": True
        }
    }
    setup_artifact(valid_data)
    
    snapshot = SelfHealWhatChangedReader.get_snapshot()
    if snapshot and snapshot.run_id == "RUN_123" and len(snapshot.artifacts_updated) == 1:
        print("✅ PASS: Correctly read valid snapshot.")
        proof_data["scenarios"].append({"name": "VALID_SNAPSHOT", "result": "PASS"})
    else:
        print(f"❌ FAIL: Failed to read valid snapshot. Got {snapshot}")
        proof_data["scenarios"].append({"name": "VALID_SNAPSHOT", "result": "FAIL"})
        
    # 3. Invalid Data (Schema Violation)
    print("\n--- Scenario: Invalid Data ---")
    invalid_data = valid_data.copy()
    del invalid_data["timestamp_utc"] # Missing required field
    setup_artifact(invalid_data)
    
    snapshot = SelfHealWhatChangedReader.get_snapshot()
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
