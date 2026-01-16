import sys
from pathlib import Path
import json
import logging

# Add project root to sys.path
root_dir = Path(__file__).resolve().parent.parent
sys.path.append(str(root_dir))

from backend.os_ops.immune_system import ImmuneSystemEngine

# Setup output paths
OUTPUT_DIR = Path("backend/outputs/runtime/day_32")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
VERIFY_FILE = OUTPUT_DIR / "day_32_verify.json"
PROOF_FILE = OUTPUT_DIR / "day_32_war_room_proof.json"

results = {
    "tests": [],
    "artifacts_check": {},
    "status": "In Progress"
}

def log_test(name, passed, details=""):
    results["tests"].append({
        "name": name,
        "passed": passed,
        "details": details
    })
    print(f"[{'PASS' if passed else 'FAIL'}] {name} - {details}")

def main():
    print("=== Day 32: Immune System Verification ===")
    
    # 1. Clean Payload Test
    clean_payload = {
        "price": 100.50,
        "volatility": 15.2,
        "timestamp_utc": "2026-01-16T12:00:00Z"
    }
    try:
        res1 = ImmuneSystemEngine.run(clean_payload, context={"run_id": "verify_001"})
        passed = (res1["status"] == "CLEAN" and len(res1["flags"]) == 0)
        log_test("Clean Payload", passed, f"Status: {res1['status']}")
    except Exception as e:
        log_test("Clean Payload", False, str(e))
        
    # 2. Poisoned Payload (Missing Keys / NULL)
    try:
        res2 = ImmuneSystemEngine.run({}, context={"run_id": "verify_002"})
        passed = ("NULL_PACKET" in res2["flags"])
        log_test("Null Packet", passed, f"Flags: {res2['flags']}")
    except Exception as e:
        log_test("Null Packet", False, str(e))
        
    # 3. Numeric Anomaly (NaN/Negative)
    poison_payload = {
        "price": float('nan'),
        "volatility": -5.0
    }
    try:
        res3 = ImmuneSystemEngine.run(poison_payload, context={"run_id": "verify_003"})
        passed = ("NEGATIVE_OR_NAN" in res3["flags"])
        log_test("Numeric Anomaly", passed, f"Flags: {res3['flags']}")
    except Exception as e:
        log_test("Numeric Anomaly", False, str(e))
        
    # 4. Artifact Check
    immune_root = Path("backend/outputs/runtime/immune")
    artifacts = ["immune_report.json", "immune_snapshot.json", "immune_ledger.jsonl"]
    all_artifacts = True
    for art in artifacts:
        p = immune_root / art
        exists = p.exists()
        results["artifacts_check"][art] = "EXISTS" if exists else "MISSING"
        if not exists: all_artifacts = False
        
    log_test("Artifacts Created", all_artifacts, f"Checked {artifacts}")
    
    # 5. Pipeline Non-Blocking Check (Simulated)
    # We verify that mode is SHADOW in the snapshot
    try:
        with open(immune_root / "immune_snapshot.json", "r") as f:
            snap = json.load(f)
            mode = snap.get("mode", "UNKNOWN")
            passed = (mode == "SHADOW_SANITIZE")
            log_test("Mode Verification", passed, f"Mode is {mode}")
    except Exception as e:
        log_test("Mode Verification", False, str(e))

    # 6. War Room Proof (Mock)
    # We simulate what War Room would see for immune system
    # Just creating the proof file as requested
    proof_data = {
        "latest_snapshot": snap if 'snap' in locals() else {},
        "target_mode": "SHADOW_SANITIZE"
    }
    with open(PROOF_FILE, "w") as f:
        json.dump(proof_data, f, indent=2)
        
    # Finalize
    all_passed = all(t["passed"] for t in results["tests"])
    results["status"] = "PASSED" if all_passed else "FAILED"
    
    with open(VERIFY_FILE, "w") as f:
        json.dump(results, f, indent=2)
        
    print(f"Verification Complete. Status: {results['status']}")
    if not all_passed:
        exit(1)

if __name__ == "__main__":
    main()
