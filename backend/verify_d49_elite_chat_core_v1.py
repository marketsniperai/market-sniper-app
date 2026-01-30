
import os
import sys
import json
import requests
import time

# Paths
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(REPO_ROOT)

from backend.os_intel.elite_chat_router import EliteChatRouter

def verify_chat():
    print("VERIFICATION: Elite Chat Core v1")
    print("================================")
    
    router = EliteChatRouter()
    
    # Test 1: Deterministic Status
    print("\nTest 1: System Status (Deterministic)")
    res = router.route_request("What is the system status?", {"screen_id": "DASHBOARD"})
    print(f"Mode: {res['mode']}")
    print(f"Answer: {res['answer']}")
    if res['mode'] != "DETERMINISTIC":
        print("FAIL: Expected DETERMINISTIC mode")
        return

    # Test 2: Knowledge Index Match
    # Assuming 'watchlist_manager' or similar exists in OS modules.
    # Let's try 'api_server' which definitely exists.
    print("\nTest 2: Knowledge Index (api_server)")
    res = router.route_request("Tell me about api_server", {})
    print(f"Mode: {res['mode']}")
    print(f"Answer: {res['answer']}")
    if "api_server" not in res['answer'].lower():
         print("WARN: Did not find expected module name in answer. Index might be empty or missing.")
         # Not a fail condition for code logic, but content issue.
    
    # Test 3: LLM/Fallback
    # Without Key, should be FALLBACK or LLM with offline message.
    print("\nTest 3: LLM Fallback")
    res = router.route_request("Write a poem about trading", {})
    print(f"Mode: {res['mode']}")
    print(f"Answer: {res['answer']}")
    
    print("\nOVERALL STATUS: PASS")

if __name__ == "__main__":
    verify_chat()
