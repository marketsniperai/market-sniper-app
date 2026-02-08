import argparse
import requests
import json
import sys
import os
import time
from pathlib import Path
from datetime import datetime

try:
    import jsonschema
    JSONSCHEMA_AVAILABLE = True
except ImportError:
    JSONSCHEMA_AVAILABLE = False
    print("WARNING: jsonschema not installed. Contract validation SKIPPED.")

# Config
CONTRACTS_DIR = Path("tools/ewimsc/contracts")
ZOMBIE_REPORT_PATH = Path("outputs/proofs/D57_5_ZOMBIE_TRIAGE/zombie_report.json")

CORE_ENDPOINTS = [
    {"path": "/lab/healthz", "desc": "Critical Health Check"},
    {
        "path": "/dashboard", 
        "desc": "Dashboard UI Payload", 
        "required_keys": ["status", "schema_version"], 
        "schema_file": "dashboard_envelope.schema.json"
    },
    {
        "path": "/context", 
        "desc": "Narrative Context", 
        "required_keys": ["status", "schema_version"],
        "schema_file": "context_envelope.schema.json"
    },
    {"path": "/agms/foundation", "desc": "Data Truth Foundation"}, 
    {
        "path": "/pulse", 
        "desc": "Realtime Pulse",
        "schema_file": "pulse.schema.json"
    },
    {"path": "/briefing", "desc": "Morning Briefing"},
    {"path": "/aftermarket", "desc": "Aftermarket Report"},
    {"path": "/news_digest", "desc": "Intel News Digest"}
]

NEGATIVE_TESTS = [
    {"id": "NEG_01_404", "endpoint": "/does_not_exist", "method": "GET", "expected_status": 404, "desc": "Standard 404 behavior"},
    {"id": "NEG_02_PUBLIC_LAB_SHIELD_HEALTH", "endpoint": "/lab/os/health", "method": "GET", "expected_status": 404, "desc": "Public Shield on Lab Health (Hidden)", "headers": {}}, 
    {"id": "NEG_03_PUBLIC_LAB_SHIELD_WARROOM", "endpoint": "/lab/war_room", "method": "GET", "expected_status": 404, "desc": "Public Shield on War Room (Hidden)", "headers": {}}, 
    {"id": "NEG_04_METHOD", "endpoint": "/dashboard", "method": "POST", "expected_status": 405, "desc": "Method Not Allowed (POST to GET dict)"},
]

TIMEOUT = 2

def validate_schema(data, schema_filename):
    if not JSONSCHEMA_AVAILABLE:
        return True, "SKIPPED_NO_LIB"
        
    schema_path = CONTRACTS_DIR / schema_filename
    if not schema_path.exists():
        return False, f"MISSING_SCHEMA_FILE: {schema_filename}"
        
    try:
        with open(schema_path, "r") as f:
            schema = json.load(f)
        jsonschema.validate(instance=data, schema=schema)
        return True, "OK"
    except jsonschema.exceptions.ValidationError as e:
        return False, f"VALIDATION_ERROR: {e.message}"
    except Exception as e:
        return False, f"SCHEMA_ERROR: {str(e)}"

def run_core_suite(base_url, output_dir):
    print(f"\n--- RUNNING SUITE: CORE ---")
    
    out_path = Path(output_dir)
    (out_path / "http").mkdir(exist_ok=True, parents=True)
    
    results = []
    contracts_results = []
    verdict_lines = []
    suite_pass = True
    
    for ep in CORE_ENDPOINTS:
        path = ep["path"]
        url = f"{base_url}{path}"
        desc = ep["desc"]
        
        print(f"Checking {desc} ({path})...", end=" ")
        sys.stdout.flush() 
        
        result = {
            "endpoint": path,
            "desc": desc,
            "timestamp": datetime.now().isoformat(),
            "pass": False,
            "status_code": 0,
            "error": None
        }
        
        try:
            resp = requests.get(url, timeout=TIMEOUT)
            result["status_code"] = resp.status_code
            
            slug = path.strip("/").replace("/", "_")
            with open(out_path / "http" / f"{slug}.json", "w", encoding="utf-8") as f:
                f.write(resp.text)
            
            if resp.status_code == 200:
                try:
                    data = resp.json()
                    
                    if "required_keys" in ep:
                        missing = [k for k in ep["required_keys"] if k not in data]
                        if missing:
                            result["error"] = f"Missing keys: {missing}"
                            print(f"FAIL (Keys: {missing})")
                            verdict_lines.append(f"FAIL: CONTRACT_{path}_MISSING_KEYS")
                            suite_pass = False
                        else:
                            result["pass"] = True
                            
                    else:
                        result["pass"] = True
                        
                    if "schema_file" in ep:
                        valid, msg = validate_schema(data, ep["schema_file"])
                        contract_res = {
                            "endpoint": path,
                            "schema": ep["schema_file"],
                            "pass": valid,
                            "msg": msg
                        }
                        contracts_results.append(contract_res)
                        
                        if not valid:
                            print(f"FAIL (Schema: {msg})")
                            verdict_lines.append(f"FAIL: CONTRACT_{path}_{msg}")
                            suite_pass = False
                            result["pass"] = False
                            result["error"] = f"Schema Failure: {msg}"
                    
                    if result["pass"]:
                        print("PASS")

                except json.JSONDecodeError:
                    result["error"] = "Invalid JSON"
                    print("FAIL (Invalid JSON)")
                    verdict_lines.append(f"FAIL: CONTRACT_{path}_INVALID_JSON")
                    suite_pass = False
            else:
                result["error"] = f"HTTP {resp.status_code}"
                print(f"FAIL ({resp.status_code})")
                verdict_lines.append(f"FAIL: ENDPOINT_{path}_HTTP_{resp.status_code}")
                suite_pass = False
                
        except Exception as e:
            result["error"] = str(e)
            print(f"FAIL (Exception: {e})")
            verdict_lines.append(f"FAIL: EXCEPTION_{path}")
            suite_pass = False
            
        results.append(result)

    with open(out_path / "core_report.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    with open(out_path / "contract_report.json", "w", encoding="utf-8") as f:
        json.dump(contracts_results, f, indent=2)
        
    return suite_pass, verdict_lines

def run_auto_lab_suite(base_url, output_dir):
    print(f"\n--- RUNNING SUITE: AUTO LAB PROTECTION (FULL STEEL) ---")
    
    if not ZOMBIE_REPORT_PATH.exists():
        print(f"WARNING: Zombie report not found at {ZOMBIE_REPORT_PATH}. Skipping Auto-LAB.")
        return True, ["WARN: NO_ZOMBIE_REPORT"], []

    try:
        with open(ZOMBIE_REPORT_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        return False, [f"FAIL: ZOMBIE_REPORT_READ_ERROR_{e}"], []

    routes = data.get("routes", [])
    
    # D59: Support both LAB_INTERNAL (404) and ELITE_GATED (403)
    lab_routes = [r for r in routes if r["status"] == "LAB_INTERNAL"]
    elite_routes = [r for r in routes if r["status"] == "ELITE_GATED"]
    
    print(f"Loaded {len(lab_routes)} LAB_INTERNAL (404) and {len(elite_routes)} ELITE_GATED (403) routes.")
    
    all_routes = []
    for r in lab_routes:
        all_routes.append({"route": r, "expect": 404, "label": "HIDDEN"})
    for r in elite_routes:
        all_routes.append({"route": r, "expect": 403, "label": "LOCKED"})
        
    results = []
    verdict_lines = []
    suite_pass = True
    
    # D57.6.1: Harden Networking
    # Use Session with restricted pool to force fresh connections (soft-limit)
    # But explicitly sending Connection: close header is key.
    session = requests.Session()
    adapter = requests.adapters.HTTPAdapter(pool_connections=1, pool_maxsize=1, max_retries=0)
    session.mount("http://", adapter)
    session.headers.update({"Connection": "close"}) # Force Close
    
    for item in all_routes:
        r = item["route"]
        expected = item["expect"]
        label = item["label"]
        
        path = r["normalized_path"]
        method = r["methods"][0] # Just check first method
        if method not in ["GET", "POST"]: continue # Skip weird ones for now
        
        url = f"{base_url}{path}"
        tid = f"NEG_AUTO_{label}_{path.replace('/','_')}"
        
        print(f"Protect {method} {path}...", end=" ")
        sys.stdout.flush()
        
        start_time = time.time()
        result = {
            "id": tid,
            "endpoint": path,
            "expected_status": expected,
            "actual_status": 0,
            "pass": False,
            "latency_ms": 0,
            "error": None
        }
        
        try:
            # D57.6.1: Connect=2s, Read=10s. Strict Fail on Timeout.
            kwargs = {"timeout": (2, 10)}
            if method == "POST":
                kwargs["json"] = {}
                
            resp = session.request(method, url, **kwargs)
            try:
                result["actual_status"] = resp.status_code
                
                if resp.status_code == expected:
                    result["pass"] = True
                    print(f"PASS ({expected} {label})")
                else:
                    print(f"FAIL (Got {resp.status_code})")
                    verdict_lines.append(f"FAIL: LAB_LEAK_{path}_GOT_{resp.status_code}")
                    suite_pass = False
            finally:
                resp.close()
                
        except Exception as e:
            # STRICT FAIL on Exception (Timeout or otherwise)
            result["error"] = str(e)
            print(f"FAIL (Exception: {e})")
            # Clear lines to keep report clean? No, track detail.
            verdict_lines.append(f"FAIL: LAB_CHECK_EXC_{path}")
            suite_pass = False
        
        result["latency_ms"] = int((time.time() - start_time) * 1000)
        results.append(result)
        
        # Pacing to let server socket cleanup
        time.sleep(0.05)
        
    # Write Dedicated Lab Report
    out_path = Path(output_dir)
    with open(out_path / "lab_internal_report.json", "w", encoding="utf-8") as f:
        json.dump({
            "timestamp": datetime.now().isoformat(),
            "routes_checked": len(results),
            "suite_pass": suite_pass,
            "results": results
        }, f, indent=2)
        
    return suite_pass, verdict_lines, results


def run_negative_suite(base_url, output_dir):
    print(f"\n--- RUNNING SUITE: NEGATIVE ---")
    
    out_path = Path(output_dir)
    results = []
    verdict_lines = []
    suite_pass = True
    
    # Static Negatives
    for test in NEGATIVE_TESTS:
        tid = test["id"]
        path = test["endpoint"]
        url = f"{base_url}{path}"
        method = test["method"]
        expected = test["expected_status"]
        desc = test["desc"]
        headers = test.get("headers", {})
        
        print(f"[{tid}] {desc} ({method} {path} -> {expected})...", end=" ")
        
        result = {
            "id": tid,
            "endpoint": path,
            "expected_status": expected,
            "actual_status": 0,
            "pass": False
        }
        
        try:
            resp = requests.request(method, url, headers=headers, timeout=TIMEOUT)
            result["actual_status"] = resp.status_code
            
            if resp.status_code == expected:
                result["pass"] = True
                print("PASS")
            else:
                print(f"FAIL (Got {resp.status_code})")
                verdict_lines.append(f"FAIL: {tid}_EXPECTED_{expected}_GOT_{resp.status_code}")
                suite_pass = False
                
        except Exception as e:
            print(f"FAIL (Exception: {e})")
            verdict_lines.append(f"FAIL: {tid}_EXCEPTION")
            suite_pass = False
            
        results.append(result)
    
    # Auto Lab Logic
    lab_pass, lab_verdicts, lab_results = run_auto_lab_suite(base_url, output_dir)
    suite_pass = suite_pass and lab_pass
    verdict_lines.extend(lab_verdicts)
    results.extend(lab_results)
        
    with open(out_path / "negative_report.json", "w", encoding="utf-8") as f:
        json.dump({
            "suite": "negative",
            "timestamp": datetime.now().isoformat(),
            "tests": results,
            "summary": {"pass": suite_pass}
        }, f, indent=2)
        
    return suite_pass, verdict_lines

def run_harness(base_url, output_dir, suite):
    print(f"--- D57 EWIMSC HARNESS (Suite: {suite}) ---")
    print(f"Target: {base_url}")
    print(f"Output: {output_dir}")
    
    out_path = Path(output_dir)
    out_path.mkdir(parents=True, exist_ok=True)
    
    verdict_lines = []
    overall_pass = True
    
    if suite in ["core", "all"]:
        p, v = run_core_suite(base_url, output_dir)
        overall_pass = overall_pass and p
        verdict_lines.extend(v)
        
    if suite in ["negative", "all"]:
        p, v = run_negative_suite(base_url, output_dir)
        overall_pass = overall_pass and p
        verdict_lines.extend(v)
        
    print("\n--- SUMMARY ---")
    verdict_path = out_path / "VERDICT.txt"
    final_blob = ""
    
    if overall_pass:
        msg = f"PASS: EWIMSC_{suite.upper()}_OK"
        print(msg)
        final_blob = msg
    else:
        print(f"FAIL: {len(verdict_lines)} issues")
        for line in verdict_lines:
            print(f" - {line}")
        final_blob = "\n".join(verdict_lines)
        
    with open(verdict_path, "w", encoding="utf-8") as f:
        f.write(final_blob)
        
    return 0 if overall_pass else 1

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True, help="Base API URL")
    parser.add_argument("--out", required=True, help="Output directory")
    parser.add_argument("--suite", default="core", choices=["core", "negative", "all"], help="Test suite to run")
    args = parser.parse_args()
    
    sys.exit(run_harness(args.url, args.out, args.suite))
