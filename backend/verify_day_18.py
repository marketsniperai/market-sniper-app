import sys
import os
import json
import time
from datetime import datetime
from fastapi.testclient import TestClient
from backend.api_server import app

client = TestClient(app)

def log(msg):
    print(msg)

def verify_day_18(mode):
    log(f"--- VERIFYING DAY 18: {mode} ---")
    
    if mode == "STRUCTURE":
        start = time.time()
        resp = client.get("/lab/war_room", headers={"X-Founder-Key": "TEST-KEY"})
        latency = (time.time() - start) * 1000
        
        log(f"Status Code: {resp.status_code}")
        log(f"Latency: {latency:.2f}ms")
        
        if resp.status_code == 200:
            data = resp.json()
            modules = data.get("modules", {})
            log(f"Modules Present: {list(modules.keys())}")
            
            # Check deep keys
            log(f"AutoFix Status: {modules.get('autofix', {}).get('status')}")
            log(f"Housekeeper Status: {modules.get('housekeeper', {}).get('overall_status')}")
            
    elif mode == "TIMELINE":
        resp = client.get("/lab/war_room", headers={"X-Founder-Key": "TEST-KEY"})
        data = resp.json()
        timeline = data.get("timeline", [])
        log(f"Timeline Events: {len(timeline)}")
        
        # Print top 3 events to verify merge
        for i, event in enumerate(timeline[:3]):
            log(f"Event {i}: {event.get('timestamp')} | {event.get('source')} | {json.dumps(event.get('details'))[:50]}...")
            
    elif mode == "TRUTH":
        # 1. Force Drift (Missing Manifest)
        manifest = "backend/outputs/full/run_manifest.json"
        backup = manifest + ".truth_test"
        if os.path.exists(manifest):
            os.rename(manifest, backup)
            
        # 2. Check Dashboard
        resp = client.get("/lab/war_room", headers={"X-Founder-Key": "TEST-KEY"})
        data = resp.json()
        comparisons = data.get("truth_compare", [])
        
        found_missing = False
        for c in comparisons:
            log(f"Compare: {c['target']} -> {c['status']} ({c['actual']})")
            if c['target'] == "full/manifest" and c['status'] == "MISSING":
                found_missing = True
                
        if found_missing:
            log("SUCCESS: Truth Compare detected missing manifest.")
        else:
            log("FAILURE: Truth Compare did not detect missing manifest.")
            
        # Restore
        if os.path.exists(backup):
            os.rename(backup, manifest)

if __name__ == "__main__":
    verify_day_18(sys.argv[1])
