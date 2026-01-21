import json
import sys
import os
from pathlib import Path
from datetime import datetime, timezone

# Add root to sys.path
sys.path.append(os.getcwd())

from backend.os_ops.self_heal_confidence_reader import SelfHealConfidenceReader, CONFIDENCE_ARTIFACT_PATH

PROOF_PATH = Path("outputs/proofs/day_42/day_42_12_self_heal_confidence_proof.json")

def setup_artifact(data):
    CONFIDENCE_ARTIFACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(CONFIDENCE_ARTIFACT_PATH, "w") as f:
        json.dump(data, f)

def clean_env():
    if CONFIDENCE_ARTIFACT_PATH.exists():
        CONFIDENCE_ARTIFACT_PATH.unlink()

def main():
    print("Verifying Self-Heal Confidence (D42.12)...")
    clean_env()
    
    proof_data = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "scenarios": []
    }
    
    # 1. Missing Artifact -> UNAVAILABLE
    print("\n--- Scenario: Missing Artifact ---")
    clean_env()
    snapshot = SelfHealConfidenceReader.get_snapshot()
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
        "run_id": "RUN_999",
        "overall": "HIGH",
        "entries": [
            {
                "engine": "AUTOFIX_TIER1",
                "action_code": "REGENERATE_MISSING_ARTIFACT",
                "confidence": "HIGH",
                "evidence": ["BACKUP_CREATED", "FILE_EXISTS_AFTER"],
                "notes": "Verified existence."
            }
        ]
    }
    setup_artifact(valid_data)
    
    snapshot = SelfHealConfidenceReader.get_snapshot()
    if snapshot and snapshot.overall == "HIGH":
        print("✅ PASS: Correctly read valid snapshot.")
        proof_data["scenarios"].append({"name": "VALID_SNAPSHOT", "result": "PASS"})
    else:
        print(f"❌ FAIL: Failed to read valid snapshot. Got {snapshot}")
        proof_data["scenarios"].append({"name": "VALID_SNAPSHOT", "result": "FAIL"})
        
    # 3. Invalid Data (Schema Violation)
    print("\n--- Scenario: Invalid Data ---")
    invalid_data = valid_data.copy()
    del invalid_data["overall"] # Missing required field
    setup_artifact(invalid_data)
    
    snapshot = SelfHealConfidenceReader.get_snapshot()
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
