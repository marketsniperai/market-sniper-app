import argparse
import json
import sys
from pathlib import Path
from datetime import datetime

def main():
    parser = argparse.ArgumentParser(description="D58.1 No New Unknown Gate")
    parser.add_argument("--baseline", required=True, help="Path to baseline JSON")
    parser.add_argument("--report", required=True, help="Path to triage/zombie report JSON")
    parser.add_argument("--out", required=True, help="Path to output gate report JSON")
    args = parser.parse_args()

    baseline_path = Path(args.baseline)
    report_path = Path(args.report)
    out_path = Path(args.out)

    if not baseline_path.exists():
        print(f"FAIL: Baseline not found at {baseline_path}")
        sys.exit(1)

    if not report_path.exists():
        print(f"FAIL: Report not found at {report_path}")
        sys.exit(1)

    try:
        with open(baseline_path, "r", encoding="utf-8") as f:
            baseline_data = json.load(f)
            baseline_count = baseline_data["unknown_zombies"]
    except Exception as e:
        print(f"FAIL: Error reading baseline: {e}")
        sys.exit(1)

    try:
        with open(report_path, "r", encoding="utf-8") as f:
            report_data = json.load(f)
            # Count current UNKNOWN_ZOMBIEs
            routes = report_data.get("routes", [])
            current_unknowns = [r for r in routes if r.get("status") == "UNKNOWN_ZOMBIE"]
            current_count = len(current_unknowns)
    except Exception as e:
        print(f"FAIL: Error reading report: {e}")
        sys.exit(1)

    delta = current_count - baseline_count
    passed = delta <= 0
    
    # Write Gate Report
    gate_result = {
        "timestamp": datetime.now().isoformat(),
        "baseline_count": baseline_count,
        "current_count": current_count,
        "delta": delta,
        "pass": passed
    }
    
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(gate_result, f, indent=2)

    print(f"\n--- UNKNOWN ZOMBIE GATE ---")
    print(f"Baseline: {baseline_count}")
    print(f"Current:  {current_count}")
    print(f"Delta:    {delta}")
    
    if passed:
        print(f"VERDICT: PASS (No new zombies)")
        sys.exit(0)
    else:
        print(f"VERDICT: FAIL ({delta} new zombies found!)")
        print(f"FAILURE: The number of UNKNOWN_ZOMBIE endpoints has increased.")
        sys.exit(1)

if __name__ == "__main__":
    main()
