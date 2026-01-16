import os
import sys
import json
import shutil
from pathlib import Path

# Add repo root to path
sys.path.append(os.getcwd())

from backend.agms_dynamic_thresholds import AGMSDynamicThresholds
from backend.war_room import WarRoom
from backend.artifacts.io import get_artifacts_root, atomic_write_json

def run_verification():
    print("=== DAY 24 VERIFICATION SUITE ===")
    
    outputs_dir = Path("outputs/runtime/day_24")
    os.makedirs(outputs_dir, exist_ok=True)
    root = get_artifacts_root()
    
    p_pat = root / "runtime/agms/agms_patterns.json"
    p_pat_bak = root / "runtime/agms/agms_patterns.json.bak_verify"
    
    # 1. BASELINE RUN (No drift)
    print("\n[1] Baseline AGMS Thresholds...")
    # Ensure no stale artifacts exist
    if p_pat.exists():
        shutil.move(str(p_pat), str(p_pat_bak))
        
    res_base = AGMSDynamicThresholds.compute_thresholds()
    print(f"Baseline Multiplier: {res_base['multiplier']}")
    print(f"Stale Full: {res_base['thresholds']['stale_full_seconds']}")
    
    with open(outputs_dir / "day_24_baseline.txt", "w") as f:
        f.write(json.dumps(res_base, indent=2))
        
    if res_base['multiplier'] != 1.0:
        print("FAIL: Baseline multiplier should be 1.0")
        
    # 2. FORCED DRIFT (Inject Patterns)
    print("\n[2] Forced Drift (Tightening)...")
    
    try:
        # Mock High Drift
        mock_patterns = {
            "top_drift_types": ["MOCK_DRIFT"] * 10, # 10 types
            "total_drift_events": 100, # High count
            "unstable_modules": []
        }
        atomic_write_json(str(p_pat.relative_to(root)), mock_patterns)
        
        # Run Threshold Engine
        res_forced = AGMSDynamicThresholds.compute_thresholds()
        
        multiplier = res_forced['multiplier']
        stale_new = res_forced['thresholds']['stale_full_seconds']
        
        print(f"Forced Multiplier: {multiplier}")
        print(f"Stale Full (Tightened): {stale_new}")
        
        with open(outputs_dir / "day_24_forced_tightening.txt", "w") as f:
            f.write(json.dumps(res_forced, indent=2))
            
        if multiplier >= 1.0:
            print("FAIL: Multiplier did not tighten despite high drift.")
        else:
            print("PASS: Thresholds tightened.")
            
    finally:
        pass

    # 3. WAR ROOM CHECK
    print("\n[3] War Room Integration...")
    dashboard = WarRoom.get_dashboard()
    intel_surface = dashboard["modules"].get("agms", {}).get("intelligence", {})
    thresh = intel_surface.get("thresholds")
    
    print(f"Thresholds Visible: {thresh is not None}")
    if thresh:
        print(f"Current Multiplier in War Room: {thresh.get('multiplier')}")
    
    if not thresh:
        print("FAIL: War Room missing Thresholds panel.")
        
    with open(outputs_dir / "day_24_war_room_thresholds.txt", "w") as f:
         f.write(json.dumps(thresh, indent=2))
         
    # Cleanup
    if p_pat.exists():
        os.remove(p_pat)
    if p_pat_bak.exists():
        shutil.move(str(p_pat_bak), str(p_pat))

    print("\n=== VERIFICATION COMPLETE ===")

if __name__ == "__main__":
    run_verification()
