
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
    lkg_file = os_dir / "lkg_snapshot.json"
    
    proof = {
        "proof_timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "source_path_used": str(lkg_file),
        "tests": []
    }
    
    # 1. Missing File
    if lkg_file.exists():
        lkg_file.unlink()
        
    res_missing = IronOS.get_lkg_snapshot()
    proof["tests"].append({
        "case": "missing_file",
        "expected": None,
        "actual": res_missing,
        "result": "PASS" if res_missing is None else "FAIL"
    })
    
    # 2. Valid File
    now = datetime.now(timezone.utc)
    data = {
        "hash": "abcdef1234567890",
        "timestamp_utc": now.isoformat(),
        "size_bytes": 1024,
        "valid": True,
        "source": "unit_test"
    }
    with open(lkg_file, "w") as f:
        json.dump(data, f)
            
    res_valid = IronOS.get_lkg_snapshot()

    proof["tests"].append({
        "case": "valid_file",
        "hash_match": res_valid["hash"] == data["hash"] if res_valid else False,
        "valid_flag": res_valid["valid"] if res_valid else False,
        "result": "PASS" if res_valid and res_valid["hash"] == data["hash"] and res_valid["valid"] is True else "FAIL"
    })
    
    # 3. Invalid (but file exists) -> Should still read metadata if JSON valid
    data_invalid = {
        "hash": "badhash",
        "timestamp_utc": now.isoformat(),
        "size_bytes": 0,
        "valid": False,
        "source": "unit_test_fail"
    }
    with open(lkg_file, "w") as f:
        json.dump(data_invalid, f)
        
    res_invalid = IronOS.get_lkg_snapshot()
    proof["tests"].append({
        "case": "explicitly_invalid_lkg",
        "hash_match": res_invalid["hash"] == "badhash" if res_invalid else False,
        "valid_flag": res_invalid["valid"] if res_invalid else True,
        "result": "PASS" if res_invalid and res_invalid["valid"] is False else "FAIL"
    })
    
    # Cleanup
    if lkg_file.exists():
        lkg_file.unlink()

    # Write Proof
    day_41_dir = root / "runtime/day_41"
    day_41_dir.mkdir(parents=True, exist_ok=True)
    proof_path = day_41_dir / "day_41_09_lkg_viewer_proof.json"
    
    with open(proof_path, "w") as f:
        json.dump(proof, f, indent=2)
        
    print(f"Proof generated at: {proof_path}")

if __name__ == "__main__":
    run_proof()
