
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
    drift_file = os_dir / "os_drift_report.json"
    
    proof = {
        "proof_timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "source_path_used": str(drift_file),
        "tests": []
    }
    
    # 1. Missing File
    if drift_file.exists():
        drift_file.unlink()
        
    res_missing = IronOS.get_drift_report()
    proof["tests"].append({
        "case": "missing_file",
        "expected": None,
        "actual": res_missing,
        "result": "PASS" if res_missing is None else "FAIL"
    })
    
    # 2. No Drift (Empty List)
    with open(drift_file, "w") as f:
        json.dump({"drift": []}, f)
            
    res_empty = IronOS.get_drift_report()
    proof["tests"].append({
        "case": "no_drift",
        "count": len(res_empty["drift"]) if res_empty else -1,
        "result": "PASS" if res_empty and len(res_empty["drift"]) == 0 else "FAIL"
    })
    
    # 3. Drift Detected
    now = datetime.now(timezone.utc)
    data = {
        "drift": [
            {
                "component": "state",
                "expected": "NOMINAL",
                "observed": "DEGRADED",
                "timestamp_utc": now.isoformat()
            }
        ]
    }
    with open(drift_file, "w") as f:
        json.dump(data, f)
        
    res_drift = IronOS.get_drift_report()
    
    match = False
    if res_drift and len(res_drift["drift"]) == 1:
        entry = res_drift["drift"][0]
        if entry["component"] == "state" and entry["observed"] == "DEGRADED":
            match = True
            
    proof["tests"].append({
        "case": "drift_detected",
        "count": len(res_drift["drift"]) if res_drift else -1,
        "component_match": entry["component"] if match else None,
        "result": "PASS" if match else "FAIL"
    })
    
    # Cleanup
    if drift_file.exists():
        drift_file.unlink()

    # Write Proof
    day_41_dir = root / "runtime/day_41"
    day_41_dir.mkdir(parents=True, exist_ok=True)
    proof_path = day_41_dir / "day_41_08_drift_surface_proof.json"
    
    with open(proof_path, "w") as f:
        json.dump(proof, f, indent=2)
        
    print(f"Proof generated at: {proof_path}")

if __name__ == "__main__":
    run_proof()
