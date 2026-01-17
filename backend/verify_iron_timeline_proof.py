
import json
import os
import shutil
from pathlib import Path
from datetime import datetime, timezone

# Setup path
import sys
sys.path.append(os.getcwd())

from backend.os_ops.iron_os import IronOS
from backend.artifacts.io import get_artifacts_root

def run_proof():
    root = get_artifacts_root()
    os_dir = root / "os"
    os_dir.mkdir(parents=True, exist_ok=True)
    timeline_file = os_dir / "os_timeline.jsonl"
    
    proof = {
        "proof_timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "source_path_used": str(timeline_file),
        "tests": []
    }
    
    # 1. Missing File
    if timeline_file.exists():
        timeline_file.unlink()
        
    res_missing = IronOS.get_timeline_tail()
    proof["tests"].append({
        "case": "missing_file",
        "expected": None,
        "actual": res_missing,
        "result": "PASS" if res_missing is None else "FAIL"
    })
    
    # 2. Valid File (3 events)
    events = [
        {"timestamp": "2026-01-17T12:00:00Z", "type": "TICK", "summary": "Tick 1"},
        {"timestamp": "2026-01-17T12:00:01Z", "type": "TICK", "summary": "Tick 2"},
        {"timestamp": "2026-01-17T12:00:02Z", "type": "TICK", "summary": "Tick 3"},
    ]
    with open(timeline_file, "w") as f:
        for e in events:
            f.write(json.dumps(e) + "\n")
            
    res_valid = IronOS.get_timeline_tail(limit=10)
    proof["tests"].append({
        "case": "valid_file_small",
        "count": len(res_valid["events"]) if res_valid else 0,
        "first_event_summary": res_valid["events"][0]["summary"] if res_valid and res_valid["events"] else None,
        "result": "PASS" if res_valid and len(res_valid["events"]) == 3 and res_valid["events"][0]["summary"] == "Tick 3" else "FAIL"
    })
    
    # 3. Truncation (15 events, limit 10)
    with open(timeline_file, "w") as f:
        for i in range(15):
            e = {"timestamp": f"2026-01-17T12:00:{i:02d}Z", "type": "TICK", "summary": f"Tick {i}"}
            f.write(json.dumps(e) + "\n")
            
    res_trunc = IronOS.get_timeline_tail(limit=10)
    proof["tests"].append({
        "case": "truncation",
        "count": len(res_trunc["events"]) if res_trunc else 0,
        "first_event_summary": res_trunc["events"][0]["summary"] if res_trunc and res_trunc["events"] else None,
        "last_event_summary": res_trunc["events"][-1]["summary"] if res_trunc and res_trunc["events"] else None,
        "result": "PASS" if res_trunc and len(res_trunc["events"]) == 10 and res_trunc["events"][0]["summary"] == "Tick 14" else "FAIL"
    })
    
    # 4. Large Event Guard (8KB)
    large_payload = "X" * 9000
    with open(timeline_file, "a") as f: # Append to existing
       f.write(json.dumps({"type": "LARGE", "summary": large_payload}) + "\n") # Should be skipped
       f.write(json.dumps({"type": "NORMAL", "summary": "Normal after large"}) + "\n") # Should be read as newest
       
    res_guard = IronOS.get_timeline_tail(limit=10)
    proof["tests"].append({
        "case": "8kb_guard",
        "first_event_summary": res_guard["events"][0]["summary"] if res_guard else None,
        "skipped_large_present": any(e["type"] == "LARGE" for e in res_guard["events"]) if res_guard else False,
        "result": "PASS" if res_guard and res_guard["events"][0]["summary"] == "Normal after large" and not any(e["type"] == "LARGE" for e in res_guard["events"]) else "FAIL"
    })

    # Cleanup
    if timeline_file.exists():
        timeline_file.unlink()

    # Write Proof
    day_41_dir = root / "runtime/day_41"
    day_41_dir.mkdir(parents=True, exist_ok=True)
    proof_path = day_41_dir / "day_41_02_timeline_tail_proof.json"
    
    with open(proof_path, "w") as f:
        json.dump(proof, f, indent=2)
        
    print(f"Proof generated at: {proof_path}")

if __name__ == "__main__":
    run_proof()
