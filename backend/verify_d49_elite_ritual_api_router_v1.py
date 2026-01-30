
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

def verify_router():
    print("VERIFICATION: Elite Ritual API Router v1")
    print("========================================")
    
    router = EliteRitualRouter()
    
    # Test Cases
    test_ids = [
        "morning_briefing",
        "midday_report", 
        "market_resumed",
        "sunday_setup",
        "fake_ritual_id" # Should return OFFLINE/ERROR
    ]
    
    for rid in test_ids:
        print(f"\nTesting Ritual ID: {rid}")
        
        try:
            envelope = router.route(rid)
            print(f"Status: {envelope['status']}")
            print(f"Envelope Keys: {list(envelope.keys())}")
            
            if envelope['status'] == "OK":
                print("Payload: Found")
            elif envelope['status'] == "CALIBRATING":
                print("Payload: None (Calibrating)")
            elif envelope['status'] == "WINDOW_CLOSED":
                print("Payload: None (Window Closed)")
            elif envelope['status'] == "OFFLINE":
                print("Payload: None (Offline/Unknown)")
                
            # Validation
            if "ritual_id" not in envelope or "status" not in envelope:
                 print("FAIL: Envelope missing keys")
                 return
                 
        except Exception as e:
            print(f"FAIL: Exception {e}")
            return

    print("\nOVERALL STATUS: PASS")

if __name__ == "__main__":
    verify_router()
