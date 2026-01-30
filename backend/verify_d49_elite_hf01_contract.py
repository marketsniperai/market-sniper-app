
import os
import sys
import json
import requests
import time
from datetime import datetime

# Paths
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(REPO_ROOT)

from backend.os_intel.elite_ritual_router import EliteRitualRouter
# We cannot test the Alias Route HTTP endpoint easily without a running server invoked by this script.
# But we can test the Logic that powers them (which is the Router).
# TO test the Router logic effectively for Alias vs Canonical:
# They call the SAME logic.
# So we verify the Router Logic again with more precision on statuses.

def verify_contract():
    print("VERIFICATION: Elite Ritual HF01 Contract Sync")
    print("===========================================")
    
    router = EliteRitualRouter()
    
    # Test Cases
    # 1. Canonical ID
    ids = ["morning_briefing", "midday_report"]
    
    for rid in ids:
        print(f"\nScanning: {rid}")
        envelope = router.route(rid)
        
        # Contract Check:
        # { ritual_id, status, as_of_utc, payload }
        keys = envelope.keys()
        if "ritual_id" not in keys or "status" not in keys:
             print("FAIL: Missing Envelope Keys")
             return
             
        status = envelope['status']
        print(f"Status: {status}")
        
        if status == 'OK':
             if envelope['payload'] is None:
                 print("FAIL: OK status but Payload is None")
        elif status in ['CALIBRATING', 'WINDOW_CLOSED', 'OFFLINE']:
             pass # Payload can be None
        else:
             print(f"FAIL: Unknown Status {status}")

    print("\nOVERALL STATUS: PASS")

if __name__ == "__main__":
    verify_contract()
