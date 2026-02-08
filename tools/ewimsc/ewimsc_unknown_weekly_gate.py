import json
import os
import sys
import datetime
import argparse
from pathlib import Path

# Paths
REPO_ROOT = Path(__file__).parent.parent.parent
BASELINE_FILE = REPO_ROOT / "docs/canon/UNKNOWN_TREND_BASELINE.json"
ZOMBIE_REPORT_FILE = REPO_ROOT / "outputs/proofs/D57_5_ZOMBIE_TRIAGE/zombie_report.json"
OUTPUT_REPORT = REPO_ROOT / "outputs/proofs/D58_6_UNKNOWN_TREND/unknown_weekly_gate_report.json"

def parse_utc(iso_str):
    try:
        return datetime.datetime.fromisoformat(iso_str)
    except:
        # Fallback for some ISO variations if needed
        return datetime.datetime.strptime(iso_str.split('.')[0], "%Y-%m-%dT%H:%M:%S")

def run_gate():
    print("--- D58.6 WEEKLY UNKNOWN TREND GATE ---")
    
    # 1. Config
    strict_mode = os.environ.get("EWIMSC_WEEKLY_STRICT", "1") == "1"
    
    # 2. Start
    OUTPUT_REPORT.parent.mkdir(parents=True, exist_ok=True)
    report = {
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "status": "UNKNOWN",
        "baseline": {},
        "current": {},
        "check": {}
    }

    # 3. Read Baseline
    if not BASELINE_FILE.exists():
        print("FAIL: Baseline file missing")
        sys.exit(1)
        
    with open(BASELINE_FILE, "r") as f:
        baseline = json.load(f)
    
    baseline_count = baseline["unknown_count"]
    last_decrease = parse_utc(baseline["last_decrease_at_utc"])
    print(f"Baseline: {baseline_count} (Last Decrease: {baseline['last_decrease_at_utc']})")
    
    report["baseline"] = baseline

    # 4. Read Current
    # Note: Orchestrator must ensure this exists
    if not ZOMBIE_REPORT_FILE.exists():
         print(f"FAIL: Zombie report missing at {ZOMBIE_REPORT_FILE}")
         sys.exit(1)

    with open(ZOMBIE_REPORT_FILE, "r") as f:
        zombie_data = json.load(f)
        
    current_count = zombie_data["stats"]["unknown_zombies"]
    now_utc = datetime.datetime.utcnow()
    
    print(f"Current: {current_count}")
    report["current"] = {"count": current_count, "timestamp": now_utc.isoformat()}

    # 5. Ratchet Check (Hard Stop)
    if current_count > baseline_count:
        msg = f"FAIL: RATCHET BROKEN. Current ({current_count}) > Baseline ({baseline_count})"
        print(msg)
        report["status"] = "FAIL"
        report["check"] = {"result": "RATCHET_FAIL", "message": msg}
        with open(OUTPUT_REPORT, "w") as f:
            json.dump(report, f, indent=2)
        sys.exit(1)

    # 6. Improvement Check (Update Baseline)
    baseline_updated = False
    if current_count < baseline_count:
        print(f"SUCCESS: Count Decreased! ({baseline_count} -> {current_count})")
        print("ACTION: Updating Baseline...")
        
        baseline["unknown_count"] = current_count
        baseline["last_decrease_at_utc"] = now_utc.isoformat()
        baseline["captured_at_utc"] = now_utc.isoformat()
        
        with open(BASELINE_FILE, "w") as f:
            json.dump(baseline, f, indent=2)
            
        baseline_updated = True
        baseline_count = current_count # For trend check logic below (reset clock effectively)
        last_decrease = now_utc

    # 7. Staleness Check (Weekly Gate)
    delta = now_utc - last_decrease
    days_stagnant = delta.days
    
    print(f"Stagnation: {days_stagnant} days")
    
    report["check"] = {
        "days_stagnant": days_stagnant,
        "baseline_updated": baseline_updated
    }

    if days_stagnant >= 7:
        if strict_mode:
            msg = f"FAIL: WEEKLY STAGNATION. {days_stagnant} days since last decrease. Fix an Unknown Zombie!"
            print(msg)
            report["status"] = "FAIL"
            report["check"]["message"] = msg
            # Only fail strictly if env var set
            with open(OUTPUT_REPORT, "w") as f:
                json.dump(report, f, indent=2)
            sys.exit(1)
        else:
            msg = f"WARN: WEEKLY STAGNATION. {days_stagnant} days since last decrease. (Strict Mode OFF)"
            print(msg)
            report["status"] = "WARN"
            report["check"]["message"] = msg
    else:
        print("PASS: Trend Healthy")
        report["status"] = "PASS"

    with open(OUTPUT_REPORT, "w") as f:
        json.dump(report, f, indent=2)
        
    sys.exit(0)

if __name__ == "__main__":
    run_gate()
