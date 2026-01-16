import json
import logging
import os
import shutil
import hashlib
import time
from pathlib import Path
from backend.os_ops.black_box import BlackBox

# Setup Logger
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("Day34Verify")

OUTPUT_DIR = Path("backend/outputs/runtime/day_34")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def log_test(name, result, context=None):
    logger.info(f"TEST: {name} -> {result} | {context}")

def main():
    results = {
        "status": "UNKNOWN",
        "tests": {},
        "timestamp": time.time()
    }
    
    try:
        logger.info("--- Starting Day 34 Verification: Black Box ---")
        
        # Clean state for test
        if BlackBox.LEDGER_PATH.exists():
             BlackBox.LEDGER_PATH.unlink()
        if BlackBox.SNAPSHOT_DIR.exists():
             shutil.rmtree(BlackBox.SNAPSHOT_DIR)
        
        BlackBox._last_hash = "GENESIS_DAY_34" # Reset memory
        
        # Test 1: Record Events & Hash Chain
        logger.info("Test 1: Recording Events...")
        BlackBox.record_event("TEST_EVENT", {"step": 1}, {})
        BlackBox.record_event("TEST_EVENT", {"step": 2}, {})
        
        integrity = BlackBox.verify_integrity()
        if integrity["valid"] and integrity["count"] == 2:
            results["tests"]["hash_chain"] = "PASSED"
        else:
            results["tests"]["hash_chain"] = f"FAILED: {integrity}"
            
        # Test 2: Sanitization
        logger.info("Test 2: Sanitization...")
        BlackBox.record_event("SECRET_EVENT", {"api_key": "MUST_HIDE_123", "safe": "ok"}, {})
        tail = BlackBox.get_ledger_tail(1)
        last = tail[0]
        if "***REDACTED***" in str(last["payload"]):
             results["tests"]["sanitization"] = "PASSED"
        else:
             results["tests"]["sanitization"] = f"FAILED: Secret leaked: {last['payload']}"
             
        # Test 3: Tamper Simulation
        logger.info("Test 3: Tamper Simulation...")
        # Read file, modify line 1, write back
        lines = []
        with open(BlackBox.LEDGER_PATH, "r") as f:
            lines = f.readlines()
            
        # Tamper payload of line 0
        bad_entry = json.loads(lines[0])
        bad_entry["payload"]["step"] = 999
        lines[0] = json.dumps(bad_entry) + "\n"
        
        with open(BlackBox.LEDGER_PATH, "w") as f:
            f.writelines(lines)
            
        # Reset memory state to force re-read otherwise verify might just check file? 
        # Actually verify_integrity reads file.
        integrity_bad = BlackBox.verify_integrity()
        if not integrity_bad["valid"] and integrity_bad["status"] == "TAMPERED_CONTENT":
             results["tests"]["tamper_detection"] = "PASSED"
        else:
             results["tests"]["tamper_detection"] = f"FAILED: Detected as {integrity_bad}"

        # FIX LEDGER for next tests (Append checks need valid chain or at least writeability)
        # We'll just clear it again
        if BlackBox.LEDGER_PATH.exists(): BlackBox.LEDGER_PATH.unlink()
        BlackBox._last_hash = "GENESIS_DAY_34"

        # Test 4: Crash Snapshot
        logger.info("Test 4: Crash Snapshot...")
        snap_path = BlackBox.snapshot({"state": "CRITICAL", "mem": "dump"}, "TEST_CRASH")
        if snap_path and Path(snap_path).exists():
             results["tests"]["snapshot"] = "PASSED"
        else:
             results["tests"]["snapshot"] = "FAILED"
             
        # Test 5: War Room Proof
        # We can't easily spin up whole war room logic here without mocks, 
        # but we can check if the helper returns data.
        from backend.os_ops.war_room import WarRoom
        try:
             # Ensure BlackBox has some data
             BlackBox.record_event("WR_TEST", {}, {})
             status = WarRoom._get_black_box_status()
             if status["valid"]:
                 results["tests"]["war_room_panel"] = "PASSED"
             else:
                 results["tests"]["war_room_panel"] = f"FAILED: {status}"
        except Exception as e:
             results["tests"]["war_room_panel"] = f"ERROR: {e}"

        # Final
        if all(v == "PASSED" for v in results["tests"].values()):
            results["status"] = "PASSED"
        else:
            results["status"] = "FAILED"
            
    except Exception as e:
        logger.error(f"FATAL: {e}")
        results["status"] = "CRASHED"
        results["error"] = str(e)
        
    with open(OUTPUT_DIR / "day_34_verify.json", "w") as f:
        json.dump(results, f, indent=2)
        
    print(json.dumps(results, indent=2))

if __name__ == "__main__":
    main()
