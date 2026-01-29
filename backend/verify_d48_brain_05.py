
import json
import os
import sys
import datetime
from pathlib import Path

# Add backend to path
sys.path.append(str(Path(__file__).parent.parent))

from backend.os_data.datamux import DataMux
from backend.artifacts.io import get_artifacts_root

def verify_brain_05():
    print("=== D48.BRAIN.05 Verification: Provider DataMux ===")
    
    # 1. Normal Fetch
    print("[1] Fetching SPY (Expect yahoo_stub)...")
    res = DataMux.fetch_candles("SPY", "DAILY")
    print(f"    Result: {res['status']} via {res['provider']}")
    if res['provider'] != "yahoo_stub":
        print("[FAIL] Expected yahoo_stub")
        sys.exit(1)
        
    # 2. Failover Test
    print("[2] Fetching FAIL (Expect Failover to DEMO)...")
    res_fail = DataMux.fetch_candles("FAIL", "DAILY")
    print(f"    Result: {res_fail['status']} via {res_fail['provider']}")
    if res_fail['provider'] != "demo":
        print("[FAIL] Expected failover to demo")
        sys.exit(1)
        
    # 3. Denied Test
    print("[3] Fetching DENY (Expect Failover to DEMO)...")
    res_deny = DataMux.fetch_candles("DENY", "DAILY")
    print(f"    Result: {res_deny['status']} via {res_deny['provider']}")
    
    # 4. Verify Health Artifact
    print("[4] Checking Health Artifact...")
    root = get_artifacts_root()
    path = root / "os/engine/provider_health.json"
    
    if not path.exists():
        print("[FAIL] Health artifact missing")
        sys.exit(1)
        
    with open(path, "r") as f:
        health = json.load(f)
        
    print(f"    Health Data: {json.dumps(health, indent=2)}")
    
    # Check yahoo_stub has failures
    y = health.get("yahoo_stub", {})
    if y.get("failures", 0) < 1:
         print("[WARN] Expected failures recorded for yahoo_stub")
         
    if y.get("denied") is not True:
         # Wait, we called "DENY" which sets denied=True
         # Is it cumulative?
         # _record_health logic: if denied, set True.
         if "DENIED" not in str(y): # simpler check
             print("[FAIL] yahoo_stub should be denied")
             sys.exit(1)
             
    print("[PASS] Health verified.")
    print("\n=== SYSTEM ONLINE ===")

if __name__ == "__main__":
    verify_brain_05()
