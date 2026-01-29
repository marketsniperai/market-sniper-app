import requests
import json
import sys

def verify_calendar():
    print(">>> D47.HF35: Verifying Economic Calendar API <<<")
    
    url = "http://127.0.0.1:8000/economic_calendar"
    try:
        print(f" -> GET {url}")
        resp = requests.get(url)
        
        if resp.status_code != 200:
            print(f"FAIL: Status {resp.status_code}")
            sys.exit(1)
            
        data = resp.json()
        print(" -> HTTP 200 OK")
        
        # Validate Schema
        required_keys = ["status", "asOfUtc", "source", "events"]
        missing = [k for k in required_keys if k not in data]
        
        if missing:
            print(f"FAIL: Missing keys: {missing}")
            sys.exit(1)
            
        print(f" -> Source: {data.get('source')}")
        print(f" -> Events: {len(data.get('events', []))}")
        
        if len(data.get('events', [])) > 0:
            evt = data['events'][0]
            print(f" -> Sample Event: {evt['title']} ({evt['timeUtc']})")
        else:
            print("WARN: No events returned (empty demo list?)")
            
        print("SUCCESS: API Verification Passed.")
        
        # Dump sample for evidence
        with open("outputs/proofs/hf35_calendar_activation_v1/05_sample_response.json", "w") as f:
            json.dump(data, f, indent=2)
            
    except Exception as e:
        print(f"FAIL: Exception: {e}")
        sys.exit(1)

if __name__ == "__main__":
    verify_calendar()
