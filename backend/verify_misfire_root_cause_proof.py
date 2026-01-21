import json
import requests
import sys
import os
from pathlib import Path
from datetime import datetime, timezone

# Add root to sys.path
sys.path.append(os.getcwd())

from backend.os_ops.misfire_root_cause_reader import MisfireRootCauseReader, MISFIRE_ROOT_CAUSE_PATH

PROOF_PATH = Path("outputs/proofs/day_42/day_42_11_misfire_root_cause_proof.json")

def setup_artifact(data):
    MISFIRE_ROOT_CAUSE_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(MISFIRE_ROOT_CAUSE_PATH, "w") as f:
        json.dump(data, f)

def clean_env():
    if MISFIRE_ROOT_CAUSE_PATH.exists():
        MISFIRE_ROOT_CAUSE_PATH.unlink()

def main():
    print("Verifying Misfire Root Cause (D42.11)...")
    clean_env()
    
    proof_data = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "scenarios": []
    }
    
    # 1. Missing Artifact -> UNAVAILABLE
    print("\n--- Scenario: Missing Artifact ---")
    clean_env()
    snapshot = MisfireRootCauseReader.get_snapshot()
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
        "incident_id": "INC_001",
        "misfire_type": "PIPELINE_STALE",
        "originating_module": "IRON_OS",
        "detected_by": "WATCHDOG",
        "primary_artifact": "iron_manifest.json",
        "pipeline_mode": "LIGHT",
        "fallback_used": "LKG",
        "action_taken": "AUTOHEAL_TRIGGERED",
        "outcome": "MITIGATED",
        "notes": "Stale manifest detected due to timeout."
    }
    setup_artifact(valid_data)
    
    snapshot = MisfireRootCauseReader.get_snapshot()
    if snapshot and snapshot.incident_id == "INC_001":
        print("✅ PASS: Correctly read valid snapshot.")
        proof_data["scenarios"].append({"name": "VALID_SNAPSHOT", "result": "PASS"})
    else:
        print(f"❌ FAIL: Failed to read valid snapshot. Got {snapshot}")
        proof_data["scenarios"].append({"name": "VALID_SNAPSHOT", "result": "FAIL"})
        
    # 3. Corrupt Schema
    print("\n--- Scenario: Corrupt Schema ---")
    corrupt_data = valid_data.copy()
    del corrupt_data["incident_id"] # Missing required field
    setup_artifact(corrupt_data)
    
    snapshot = MisfireRootCauseReader.get_snapshot()
    if snapshot is None:
        print("✅ PASS: Gracefully handled corrupt schema (returned None).")
        proof_data["scenarios"].append({"name": "CORRUPT_SCHEMA", "result": "PASS"})
    else:
        print(f"❌ FAIL: Should have failed validation but got {snapshot}")
        proof_data["scenarios"].append({"name": "CORRUPT_SCHEMA", "result": "FAIL"})

    # Write Proof
    PROOF_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(PROOF_PATH, "w") as f:
        json.dump(proof_data, f, indent=2)
    
    print("\n🏁 Verification Complete.")
    clean_env() # Cleanup

if __name__ == "__main__":
    main()
