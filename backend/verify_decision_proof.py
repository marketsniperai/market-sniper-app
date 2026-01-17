
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
    decision_file = os_dir / "os_decision_path.json"
    
    proof = {
        "proof_timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "source_path_used": str(decision_file),
        "tests": []
    }
    
    # 1. Missing File
    if decision_file.exists():
        decision_file.unlink()
        
    res_missing = IronOS.get_decision_path()
    proof["tests"].append({
        "case": "missing_file",
        "expected": None,
        "actual": res_missing,
        "result": "PASS" if res_missing is None else "FAIL"
    })
    
    # 2. Valid File
    now = datetime.now(timezone.utc)
    data = {
        "timestamp_utc": now.isoformat(),
        "decision_type": "ROLLBACK",
        "reason": "Integrity check failed",
        "fallback_used": True,
        "action_taken": "RESTORE_LKG",
        "source": "unit_test"
    }
    with open(decision_file, "w") as f:
        json.dump(data, f)
            
    res_valid = IronOS.get_decision_path()
    
    match = False
    if res_valid:
        if (res_valid["decision_type"] == "ROLLBACK" and 
            res_valid["fallback_used"] is True and
            res_valid["reason"] == "Integrity check failed"):
            match = True

    proof["tests"].append({
        "case": "valid_file",
        "type_match": res_valid["decision_type"] if res_valid else None,
        "fallback_match": res_valid["fallback_used"] if res_valid else None,
        "result": "PASS" if match else "FAIL"
    })
    
    # 3. Valid File (Nominal, no fallback)
    data_nominal = {
        "timestamp_utc": now.isoformat(),
        "decision_type": "CONTINUE",
        "reason": "All systems nominal",
        "fallback_used": False,
        "action_taken": None,
        "source": "unit_test"
    }
    with open(decision_file, "w") as f:
        json.dump(data_nominal, f)
        
    res_nominal = IronOS.get_decision_path()
    match_nominal = False
    if res_nominal:
        if (res_nominal["decision_type"] == "CONTINUE" and 
            res_nominal["fallback_used"] is False):
            match_nominal = True
            
    proof["tests"].append({
        "case": "nominal_decision",
        "type_match": res_nominal["decision_type"] if res_nominal else None,
        "result": "PASS" if match_nominal else "FAIL"
    })
    
    # Cleanup
    if decision_file.exists():
        decision_file.unlink()

    # Write Proof
    day_41_dir = root / "runtime/day_41"
    day_41_dir.mkdir(parents=True, exist_ok=True)
    proof_path = day_41_dir / "day_41_10_decision_path_proof.json"
    
    with open(proof_path, "w") as f:
        json.dump(proof, f, indent=2)
        
    print(f"Proof generated at: {proof_path}")

if __name__ == "__main__":
    run_proof()
