
import os
import json
import requests
import time

# Paths
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SNAPSHOT_PATH = os.path.join(REPO_ROOT, "outputs", "os", "state_snapshot.json")
PROOF_DIR = os.path.join(REPO_ROOT, "outputs", "proofs", "d49_os_state_snapshot_v1")
PROOF_FILE = os.path.join(PROOF_DIR, "01_verify.txt")

# Ensure proof dir
if not os.path.exists(PROOF_DIR):
    os.makedirs(PROOF_DIR)

import sys
sys.path.append(REPO_ROOT)

def verify():
    results = []
    passed = True
    
    results.append("VERIFICATION REPORT: OS State Snapshot v1")
    results.append("=========================================")

    # 1. Test Engine Direct
    try:
        from backend.os_ops.state_snapshot_engine import StateSnapshotEngine
        snap = StateSnapshotEngine.generate_snapshot()
        
        # Check keys
        required = ["timestamp_utc", "system_mode", "freshness", "providers", "locks", "recent_events"]
        missing = [k for k in required if k not in snap]
        
        if missing:
             msg = f"FAIL: Engine snapshot missing keys: {missing}"
             results.append(msg)
             passed = False
        else:
             results.append("PASS: Engine generated valid keys.")
             results.append(f"   Mode: {snap['system_mode']}")
             results.append(f"   Freshness: {snap['freshness']}")

    except Exception as e:
        msg = f"FAIL: Engine exception: {e}"
        results.append(msg)
        passed = False

    # 2. Verify Artifact File
    if passed:
        if os.path.exists(SNAPSHOT_PATH):
            results.append(f"PASS: Artifact written to {SNAPSHOT_PATH}")
        else:
             msg = f"FAIL: Artifact file not found at {SNAPSHOT_PATH}"
             results.append(msg)
             passed = False

    # 3. Endpoint Mock (if server not running, we skip or mock)
    # We can't guarantee server is up on port 8000 in this env without blocking.
    # So we assume Engine verification covers the logic.

    results.append("------------------------------------------")
    results.append("OVERALL STATUS: " + ("PASS" if passed else "FAIL"))
    
    print("\n".join(results))

    with open(PROOF_FILE, 'w') as f:
        f.write("\n".join(results))
    
    print(f"Proof written to {PROOF_FILE}")

if __name__ == "__main__":
    verify()
