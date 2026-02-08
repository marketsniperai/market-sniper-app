import json
import os
import sys
import datetime
from pathlib import Path

# Paths
REPO_ROOT = Path(__file__).parent.parent.parent
ZOMBIE_REPORT_FILE = REPO_ROOT / "outputs/proofs/D57_5_ZOMBIE_TRIAGE/zombie_report.json"
OUTPUT_REPORT = REPO_ROOT / "outputs/proofs/D58_X_RELEASE_GATE/release_unknown_zero_gate_report.json"

def run_gate():
    print("--- D58.X UNKNOWN=0 RELEASE GATE ---")
    
    # 1. Config
    release_mode = os.environ.get("EWIMSC_RELEASE_MODE", "0") == "1"
    
    # 2. Start
    OUTPUT_REPORT.parent.mkdir(parents=True, exist_ok=True)
    report = {
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "status": "UNKNOWN",
        "mode": "RELEASE" if release_mode else "DEV",
        "current": {},
        "check": {}
    }

    # 3. Read Current
    if not ZOMBIE_REPORT_FILE.exists():
         print(f"FAIL: Zombie report missing at {ZOMBIE_REPORT_FILE}")
         sys.exit(1)

    with open(ZOMBIE_REPORT_FILE, "r") as f:
        zombie_data = json.load(f)
        
    current_count = zombie_data["stats"]["unknown_zombies"]

    print(f"Mode: {'RELEASE (Strict)' if release_mode else 'DEV (Tolerant)'}")
    print(f"Current Unknowns: {current_count}")
    
    report["current"] = {"count": current_count}

    # 4. Release Gate Check
    if release_mode:
        if current_count == 0:
            print("SUCCESS: Unknowns are 0 in Release Mode.")
            report["status"] = "PASS"
            report["check"] = {"result": "PASS", "message": "Zero Unknowns achieved."}
        else:
            msg = f"FAIL: RELEASE BLOCKED. Release Mode requires Unknown=0. Found {current_count}."
            print(msg)
            report["status"] = "FAIL"
            report["check"] = {"result": "FAIL", "message": msg}
            with open(OUTPUT_REPORT, "w") as f:
                json.dump(report, f, indent=2)
            sys.exit(1)
            
    else:
        # Dev Mode - Just report
        print(f"PASS: Dev Mode tolerates unknowns (Count: {current_count}).")
        report["status"] = "PASS" # Always pass in dev (logic handled by Weekly gate/Ratchet)
        report["check"] = {"result": "SKIPPED", "message": "Dev Mode - Check skipped."}

    with open(OUTPUT_REPORT, "w") as f:
        json.dump(report, f, indent=2)
        
    sys.exit(0)

if __name__ == "__main__":
    run_gate()
