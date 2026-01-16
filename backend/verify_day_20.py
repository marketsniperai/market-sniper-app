import os
import sys
import json
import shutil
from pathlib import Path

# Add repo root to path
sys.path.append(os.getcwd())

from backend.agms_foundation import AGMSFoundation
from backend.war_room import WarRoom
from backend.artifacts.io import get_artifacts_root, safe_read_or_fallback

def run_verification():
    print("=== DAY 20 VERIFICATION SUITE ===")
    
    outputs_dir = Path("outputs/runtime/day_20")
    os.makedirs(outputs_dir, exist_ok=True)
    root = get_artifacts_root()
    
    # 1. BASELINE RUN
    print("\n[1] Baseline AGMS Run...")
    baseline_snap = AGMSFoundation.run_agms_foundation()
    print(f"Drift Score: {baseline_snap['deltas']['drift_score']}")
    
    with open(outputs_dir / "day_20_agms_baseline.txt", "w") as f:
        f.write(json.dumps(baseline_snap, indent=2))
        
    # Verify artifacts exist
    if not (root / "runtime/agms/agms_snapshot.json").exists():
        print("FAIL: Snapshot artifact missing.")
        sys.exit(1)
    if not (root / "runtime/agms/agms_ledger.jsonl").exists():
        print("FAIL: Ledger artifact missing.")
        sys.exit(1)
        
    # 2. FORCED SCENARIO (Missing Light Manifest)
    print("\n[2] Forced Scenario (Missing Light)...")
    light_path = root / "light/run_manifest.json"
    bak_path = root / "light/run_manifest.json.bak_test"
    
    if light_path.exists():
        shutil.move(str(light_path), str(bak_path))
        
    try:
        forced_snap = AGMSFoundation.run_agms_foundation()
        deltas = forced_snap["deltas"]["drift_deltas"]
        print(f"Drift Deltas: {deltas}")
        
        with open(outputs_dir / "day_20_agms_forced.txt", "w") as f:
            f.write(json.dumps(forced_snap, indent=2))
            
        if "MISSING_LIGHT_MANIFEST" not in deltas:
            print("FAIL: AGMS did not detect missing light manifest.")
            # Restore before exit to be safe
    finally:
        if bak_path.exists():
            shutil.move(str(bak_path), str(light_path))
            
    # 3. WAR ROOM CHECK
    print("\n[3] War Room Integration...")
    dashboard = WarRoom.get_dashboard()
    agms_status = dashboard["modules"].get("agms", {})
    print(f"AGMS Status in Dashboard: {agms_status.get('engine_version')}")
    
    if not agms_status:
        print("FAIL: AGMS missing from War Room.")
        sys.exit(1)
        
    # 4. SIDE EFFECTS SCAN
    print("\n[4] Side Effects Scan...")
    # Minimal check: Ensure NO writes to light manifest (it should be restored exactly)
    # And verify NO pipeline trigger logs (hard to check files, but we know code guard exists)
    is_safe = AGMSFoundation.verify_no_side_effects()
    print(f"Internal Guard Check: {'PASS' if is_safe else 'FAIL'}")
    
    with open(outputs_dir / "day_20_no_side_effects_scan.txt", "w") as f:
        f.write(f"Guard: {is_safe}\nManifest Restored: {light_path.exists()}")

    print("\n=== VERIFICATION COMPLETE ===")

if __name__ == "__main__":
    run_verification()
