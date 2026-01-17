
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
    lock_file = os_dir / "os_lock_reason.json"
    
    proof = {
        "proof_timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "source_path_used": str(lock_file),
        "tests": []
    }
    
    # 1. Missing File -> None
    if lock_file.exists():
        lock_file.unlink()
        
    res_missing = IronOS.get_lock_reason()
    proof["tests"].append({
        "case": "missing_file",
        "expected": None,
        "actual": res_missing,
        "result": "PASS" if res_missing is None else "FAIL"
    })
    
    # 2. No Active Lock (NONE)
    now = datetime.now(timezone.utc)
    data_none = {
        "lock_state": "NONE",
        "reason_code": "N/A",
        "reason_description": "N/A",
        "originating_module": "N/A",
        "timestamp_utc": now.isoformat()
    }
    with open(lock_file, "w") as f:
        json.dump(data_none, f)
            
    res_none = IronOS.get_lock_reason()
    proof["tests"].append({
        "case": "no_active_lock",
        "expected_state": "NONE",
        "actual_state": res_none["lock_state"] if res_none else "None",
        "result": "PASS" if res_none and res_none["lock_state"] == "NONE" else "FAIL"
    })
    
    # 3. Active Lock (LOCKED)
    data_locked = {
        "lock_state": "LOCKED",
        "reason_code": "CRITICAL_DRIFT",
        "reason_description": "Severe drift detected in core engine.",
        "originating_module": "DriftMonitor",
        "timestamp_utc": now.isoformat()
    }
    with open(lock_file, "w") as f:
        json.dump(data_locked, f)
        
    res_locked = IronOS.get_lock_reason()
    proof["tests"].append({
        "case": "active_lock",
        "expected_state": "LOCKED",
        "actual_state": res_locked["lock_state"] if res_locked else "None",
        "result": "PASS" if res_locked and res_locked["lock_state"] == "LOCKED" else "FAIL"
    })

    # Cleanup
    if lock_file.exists():
        lock_file.unlink()

    # Write Proof
    day_42_dir = root / "runtime/day_42"
    day_42_dir.mkdir(parents=True, exist_ok=True)
    proof_path = day_42_dir / "day_42_01_lock_reason_proof.json"
    
    with open(proof_path, "w") as f:
        json.dump(proof, f, indent=2)
        
    print(f"Proof generated at: {proof_path}")

if __name__ == "__main__":
    run_proof()
