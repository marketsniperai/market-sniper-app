
import json
import os
import shutil
from pathlib import Path
from datetime import datetime, timezone, timedelta

# Setup path
import sys
sys.path.append(os.getcwd())

from backend.os_ops.iron_os import IronOS
from backend.artifacts.io import get_artifacts_root

def run_proof():
    root = get_artifacts_root()
    os_dir = root / "os"
    os_dir.mkdir(parents=True, exist_ok=True)
    history_file = os_dir / "os_state_history.json"
    
    proof = {
        "proof_timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "source_path_used": str(history_file),
        "tests": []
    }
    
    # 1. Missing File
    if history_file.exists():
        history_file.unlink()
        
    res_missing = IronOS.get_state_history()
    proof["tests"].append({
        "case": "missing_file",
        "expected": None,
        "actual": res_missing,
        "result": "PASS" if res_missing is None else "FAIL"
    })
    
    # 2. Valid File (3 entries)
    now = datetime.now(timezone.utc)
    entries = [
        {"state": "NOMINAL", "timestamp_utc": (now - timedelta(minutes=2)).isoformat(), "source": "test"},
        {"state": "DEGRADED", "timestamp_utc": (now - timedelta(minutes=1)).isoformat(), "source": "test"},
        {"state": "NOMINAL", "timestamp_utc": now.isoformat(), "source": "test"},
    ]
    # Artifact expects a dict wrapper? or list? Impl supports both. Let's write list in "history" key as safest canonical form if dict.
    # Actually my impl checks `isinstance(raw_data, dict) and "history" in raw_data` OR `isinstance(raw_data, list)`.
    # Let's write as dict wrapper.
    with open(history_file, "w") as f:
        json.dump({"history": entries}, f)
            
    res_valid = IronOS.get_state_history(limit=10)
    # Expect sorted descending (newest first).
    # Entry 2 (now) should be first.
    pass_valid = False
    if res_valid and len(res_valid["history"]) == 3:
        first = res_valid["history"][0]
        if first["state"] == "NOMINAL" and first["timestamp_utc"] == entries[2]["timestamp_utc"]:
            pass_valid = True
            
    proof["tests"].append({
        "case": "valid_file_small",
        "count": len(res_valid["history"]) if res_valid else 0,
        "first_state": res_valid["history"][0]["state"] if res_valid and res_valid["history"] else None,
        "result": "PASS" if pass_valid else "FAIL"
    })
    
    # 3. Truncation (15 entries, limit 10)
    many_entries = []
    for i in range(15):
        many_entries.append({
            "state": "NOMINAL", 
            "timestamp_utc": (now - timedelta(minutes=20-i)).isoformat(), # Increasing time
            "source": f"test_{i}"
        })
        
    with open(history_file, "w") as f:
        json.dump({"history": many_entries}, f)
            
    res_trunc = IronOS.get_state_history(limit=10)
    # Should have 10 entries.
    # First entry should be the last one added (index 14, i=14).
    pass_trunc = False
    if res_trunc and len(res_trunc["history"]) == 10:
        first = res_trunc["history"][0]
        if first["source"] == "test_14":
             pass_trunc = True

    proof["tests"].append({
        "case": "truncation",
        "count": len(res_trunc["history"]) if res_trunc else 0,
        "first_source": res_trunc["history"][0]["source"] if res_trunc and res_trunc["history"] else None,
        "result": "PASS" if pass_trunc else "FAIL"
    })
    
    # Cleanup
    if history_file.exists():
        history_file.unlink()

    # Write Proof
    day_41_dir = root / "runtime/day_41"
    day_41_dir.mkdir(parents=True, exist_ok=True)
    proof_path = day_41_dir / "day_41_07_state_history_proof.json"
    
    with open(proof_path, "w") as f:
        json.dump(proof, f, indent=2)
        
    print(f"Proof generated at: {proof_path}")

if __name__ == "__main__":
    run_proof()
