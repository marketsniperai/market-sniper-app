import sys
import os
import json
import time
from datetime import datetime, timedelta, timezone
from fastapi.testclient import TestClient
from backend.api_server import app

# Setup
client = TestClient(app)

def log(msg):
    print(msg)

def verify_day_17(mode):
    log(f"--- VERIFYING DAY 17: {mode} ---")
    
    if mode == "BASELINE":
        # 1. Baseline Scan
        resp = client.get("/housekeeper")
        log(f"Status Code: {resp.status_code}")
        data = resp.json()
        log(f"Overall Status: {data.get('overall_status')}")
        log(f"Candidates Found: {len(data.get('candidates', []))}")
        
    elif mode == "FORCED":
        # 1. Create Garbage
        # A. Old Temp File (>1h)
        trash_tmp = "backend/outputs/trash_17.tmp"
        with open(trash_tmp, "w") as f: f.write("Garbage")
        # Set mtime to 2 hours ago
        two_hours_ago = time.time() - 7200
        os.utime(trash_tmp, (two_hours_ago, two_hours_ago))
        
        # B. Recent Temp File (<1h) - Should NOT be safe to clean
        recent_tmp = "backend/outputs/recent_17.tmp"
        with open(recent_tmp, "w") as f: f.write("Fresh Garbage")
        
        # C. Orphan Lock (>1h)
        lock_path = "backend/outputs/os_lock.json" 
        # Note: In our setup, get_artifacts_root() points to backend/outputs, 
        # so os_lock is typically there or one level up? 
        # Housekeeper scans 'backend/outputs'. 
        # Wait, Housekeeper.scan() uses get_artifacts_root() which is backend/outputs.
        # But os_lock usually sits there? 
        # Let's check where it writes.
        # autofix_control_plane.py: LOCK_FILE_PATH = "os_lock.json" (relative to cwd typically or root)
        # Housekeeper scans recursively from root.
        
        # Creating a specific lock file inside outputs to be sure it's scanned
        lock_target = "backend/outputs/os_lock.json"
        stuck_ts = (datetime.now(timezone.utc) - timedelta(hours=2)).isoformat()
        with open(lock_target, "w") as f:
            json.dump({"timestamp_utc": stuck_ts, "pid": 9999}, f)
            
        log("Created: trash_17.tmp (old), recent_17.tmp (new), os_lock.json (stuck)")
        
        # 2. Scan Again
        resp = client.get("/housekeeper")
        data = resp.json()
        log(f"Overall Status: {data.get('overall_status')}")
        
        candidates = data.get("candidates", [])
        for c in candidates:
            log(f"Candidate: {c['path']} | Status: {c['status']}")

    elif mode == "EXECUTE":
        # 1. Execute Cleanup
        resp = client.post("/lab/housekeeper/run", headers={"X-Founder-Key": "TEST-KEY"})
        data = resp.json()
        log(f"Cleaned Items: {data.get('items_cleaned')}")
        
        # 2. Verify Deletion
        trash_tmp = "backend/outputs/trash_17.tmp"
        recent_tmp = "backend/outputs/recent_17.tmp"
        lock_target = "backend/outputs/os_lock.json"
        
        if not os.path.exists(trash_tmp):
            log("trash_17.tmp: DELETED (Correct)")
        else:
            log("trash_17.tmp: EXISTS (Fail)")
            
        if os.path.exists(recent_tmp):
            log("recent_17.tmp: EXISTS (Correct)")
        else:
            log("recent_17.tmp: DELETED (Fail - Should be protected)")
            
        if not os.path.exists(lock_target):
            log("os_lock.json: DELETED (Correct)")
        else:
            log("os_lock.json: EXISTS (Fail)")

    elif mode == "DRIFT":
        # 1. Simulate Drift (Missing Manifest)
        # Rename full manifest
        manifest = "backend/outputs/full/run_manifest.json"
        backup = manifest + ".drift_test"
        if os.path.exists(manifest):
            os.rename(manifest, backup)
            
        # 2. Scan
        resp = client.get("/housekeeper")
        data = resp.json()
        log(f"Overall Status: {data.get('overall_status')}")
        log(f"Drift Warnings: {data.get('drift_warnings')}")
        
        # Restore
        if os.path.exists(backup):
            os.rename(backup, manifest)

if __name__ == "__main__":
    verify_day_17(sys.argv[1])
