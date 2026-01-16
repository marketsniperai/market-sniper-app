import json
import os
import sys
import shutil
from pathlib import Path
from typing import List

# Fix Path
sys.path.append(os.getcwd())

from backend.os_ops.playbook_coverage_scan import PlaybookCoverageScanner, KNOWN_PATTERNS
from backend.os_ops.autofix_control_plane import AutoFixControlPlane
from backend.artifacts.io import atomic_write_json, get_artifacts_root

OUTPUT_DIR = "outputs/runtime/day_28_01"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def run_test(name, assertion_func):
    print(f"--- TEST: {name} ---")
    try:
        result = assertion_func()
        if result:
            print("PASS")
            return True
        else:
            print("FAIL")
            return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False

def test_coverage_baseline():
    result = PlaybookCoverageScanner.scan_coverage()
    with open(f"{OUTPUT_DIR}/day_28_01_baseline_coverage.json", "w") as f:
        json.dump(result, f, indent=2)
        
    print(f"Details: {result['metrics']}")
    return result["status"] == "PASS"

def test_forced_uncovered():
    # Inject a fake pattern into KNOWN_PATTERNS for this test
    # Since KNOWN_PATTERNS is a global list in the module, modifying it affects the scan
    KNOWN_PATTERNS.append("FORCED_UNCOVERED_PATTERN_XYZ")
    
    result = PlaybookCoverageScanner.scan_coverage()
    with open(f"{OUTPUT_DIR}/day_28_01_forced_uncovered.json", "w") as f:
        json.dump(result, f, indent=2)
    
    # Remove it for cleanup
    KNOWN_PATTERNS.pop()
    
    uncovered = result.get("uncovered_patterns", [])
    if "FORCED_UNCOVERED_PATTERN_XYZ" in uncovered and result["status"] == "WARN":
        return True
    return False

def test_v2_loader():
    pbs = AutoFixControlPlane.load_playbooks()
    
    # Check if we loaded ~26
    count = len(pbs)
    print(f"Loaded Playbooks: {count}")
    
    if count < 20: 
        print("FAIL: Loaded count too low")
        return False
        
    # Check V2 mapping
    # Pick a V2 playbook, e.g. PB-T1-API-ERROR-SPIKE
    target = next((p for p in pbs if p["playbook_id"] == "PB-T1-API-ERROR-SPIKE"), None)
    if not target:
        print("FAIL: V2 Playbook PB-T1-API-ERROR-SPIKE not found")
        return False
        
    # Check Symptoms mapping
    if "API_ERROR_RATE_HIGH" not in target.get("symptoms", []):
        print(f"FAIL: V2 internal mapping bad. Symptoms: {target.get('symptoms')}")
        return False
        
    # Check Allowed Actions
    if "NOOP_REPORT" not in target.get("allowed_actions", []):
         print(f"FAIL: V2 internal action mapping bad. Actions: {target.get('allowed_actions')}")
         return False
         
    return True

def main():
    failures = []
    
    if not run_test("Coverage Baseline", test_coverage_baseline):
        failures.append("Coverage Baseline")
        
    if not run_test("Forced Uncovered Logic", test_forced_uncovered):
        failures.append("Forced Uncovered Logic")
        
    if not run_test("V2 Playbook Loader", test_v2_loader):
        failures.append("V2 Playbook Loader")
        
    if failures:
        print(f"FAILURES: {failures}")
        sys.exit(1)
    else:
        print("ALL TESTS PASSED")
        sys.exit(0)

if __name__ == "__main__":
    main()
