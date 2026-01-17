
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
    replay_file = os_dir / "os_replay_integrity.json"
    
    proof = {
        "proof_timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "source_path_used": str(replay_file),
        "tests": []
    }
    
    # 1. Missing File
    if replay_file.exists():
        replay_file.unlink()
        
    res_missing = IronOS.get_replay_integrity()
    proof["tests"].append({
        "case": "missing_file",
        "expected": None,
        "actual": res_missing,
        "result": "PASS" if res_missing is None else "FAIL"
    })
    
    # 2. Perfect Integrity
    now = datetime.now(timezone.utc)
    data_ok = {
        "corrupted": False,
        "truncated": False,
        "out_of_order": False,
        "duplicate_events": False,
        "timestamp_utc": now.isoformat()
    }
    with open(replay_file, "w") as f:
        json.dump(data_ok, f)
            
    res_ok = IronOS.get_replay_integrity()
    passed_ok = False
    if res_ok:
        if (not res_ok["corrupted"] and 
            not res_ok["truncated"] and 
            not res_ok["out_of_order"] and 
            not res_ok["duplicate_events"]):
            passed_ok = True
            
    proof["tests"].append({
        "case": "perfect_integrity",
        "result": "PASS" if passed_ok else "FAIL"
    })
    
    # 3. Corrupted
    data_bad = {
        "corrupted": True,
        "truncated": True,
        "out_of_order": False,
        "duplicate_events": False,
        "timestamp_utc": now.isoformat()
    }
    with open(replay_file, "w") as f:
        json.dump(data_bad, f)
        
    res_bad = IronOS.get_replay_integrity()
    passed_bad = False
    if res_bad:
        if res_bad["corrupted"] is True and res_bad["truncated"] is True:
            passed_bad = True
            
    proof["tests"].append({
        "case": "integrity_issues",
        "corrupted_match": res_bad["corrupted"] if res_bad else None,
        "truncated_match": res_bad["truncated"] if res_bad else None,
        "result": "PASS" if passed_bad else "FAIL"
    })
    
    # Cleanup
    if replay_file.exists():
        replay_file.unlink()

    # Write Proof
    day_41_dir = root / "runtime/day_41"
    day_41_dir.mkdir(parents=True, exist_ok=True)
    proof_path = day_41_dir / "day_41_11_replay_integrity_proof.json"
    
    with open(proof_path, "w") as f:
        json.dump(proof, f, indent=2)
        
    print(f"Proof generated at: {proof_path}")

if __name__ == "__main__":
    run_proof()
