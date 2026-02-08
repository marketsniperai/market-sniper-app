import requests
import sys
import json
import argparse
from pathlib import Path

# Config
OUTPUT_DIR = Path("outputs/proofs/D58_5_ELITE_GATING")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

SENSITIVE_ENDPOINTS = [
    {"path": "/elite/chat", "method": "POST", "body": {"message": "test"}},
    {"path": "/elite/reflection", "method": "POST", "body": {"text": "test"}},
    {"path": "/elite/settings", "method": "POST", "body": {"setting": "test"}}
]

def run_suite():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8788)
    args = parser.parse_args()
    
    base_url = f"http://127.0.0.1:{args.port}"
    print(f"--- ELITE NEGATIVE SUITE (Port {args.port}) ---")
    
    results = []
    failed = False

    # 1. Unauthenticated (Expect 403)
    print("\n[TEST] Unauthenticated Access (Expect 403)")
    for ep in SENSITIVE_ENDPOINTS:
        try:
            url = f"{base_url}{ep['path']}"
            if ep['method'] == "POST":
                resp = requests.post(url, json=ep['body'], timeout=5)
            else:
                resp = requests.get(url, timeout=5)
            
            status = "PASS" if resp.status_code == 403 else "FAIL"
            if resp.status_code != 403:
                failed = True
                print(f"FAIL: {ep['path']} returned {resp.status_code} (expected 403)")
            else:
                # Check Body
                try:
                    data = resp.json()
                    if data.get("detail") != "NOT_AUTHORIZED":
                        status = "WARN" # 403 but detail mismatch
                        print(f"WARN: {ep['path']} detail={data.get('detail')} (expected NOT_AUTHORIZED)")
                except:
                    pass

            results.append({
                "test": f"UNAUTH_{ep['path']}",
                "status": status,
                "code": resp.status_code,
                "expected": 403
            })
        except Exception as e:
            failed = True
            print(f"ERROR: {ep['path']} exception: {e}")
            results.append({"test": f"UNAUTH_{ep['path']}", "status": "ERROR", "error": str(e)})

    # 2. Authenticated (Elite Header Override) (Expect !403)
    print("\n[TEST] Authenticated Access (Elite Header Override) (Expect !403)")
    headers = {"X-Test-Elite-Entitled": "TRUE"}
    for ep in SENSITIVE_ENDPOINTS:
        try:
            url = f"{base_url}{ep['path']}"
            if ep['method'] == "POST":
                resp = requests.post(url, json=ep['body'], headers=headers, timeout=5)
            else:
                resp = requests.get(url, headers=headers, timeout=5)
            
            # We fail if it is 403 (means gate ignored override)
            status = "PASS" if resp.status_code != 403 else "FAIL"
            if resp.status_code == 403:
                failed = True
                print(f"FAIL: {ep['path']} returned 403 despite Entitlement Header")
            
            results.append({
                "test": f"AUTH_{ep['path']}",
                "status": status,
                "code": resp.status_code,
                "expected": "NOT 403"
            })
        except Exception as e:
            failed = True
            print(f"ERROR: {ep['path']} exception: {e}")
            results.append({"test": f"AUTH_{ep['path']}", "status": "ERROR", "error": str(e)})

    # Report
    report_file = OUTPUT_DIR / "elite_negative_report.json"
    with open(report_file, "w") as f:
        json.dump(results, f, indent=2)
    
    print(f"\nReport: {report_file}")
    
    if failed:
        print("Suite FAILED")
        sys.exit(1)
    else:
        print("Suite PASSED")
        sys.exit(0)

if __name__ == "__main__":
    run_suite()
