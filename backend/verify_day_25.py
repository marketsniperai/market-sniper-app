import os
import sys
import json
import shutil
from pathlib import Path

# Add repo root to path
sys.path.append(os.getcwd())

from backend.agms_stability_bands import AGMSStabilityBands
from backend.war_room import WarRoom
from backend.artifacts.io import get_artifacts_root, atomic_write_json

def run_verification():
    print("=== DAY 25 VERIFICATION SUITE ===")
    
    outputs_dir = Path("outputs/runtime/day_25")
    os.makedirs(outputs_dir, exist_ok=True)
    root = get_artifacts_root()
    
    p_pat = root / "runtime/agms/agms_patterns.json"
    p_coh = root / "runtime/agms/agms_coherence_snapshot.json"
    
    p_pat_bak = root / "runtime/agms/agms_patterns.json.bak_verify"
    p_coh_bak = root / "runtime/agms/agms_coherence_snapshot.json.bak_verify"
    
    # 1. BASELINE RUN (Should be GREEN if nominal)
    print("\n[1] Baseline Stability Band...")
    
    # Backup existing
    if p_pat.exists(): shutil.move(str(p_pat), str(p_pat_bak))
    if p_coh.exists(): shutil.move(str(p_coh), str(p_coh_bak))
    
    # Mock Green State (Nominal)
    atomic_write_json(str(p_coh.relative_to(root)), {"score": 95})
    atomic_write_json(str(p_pat.relative_to(root)), {"total_drift_events": 0})
    
    res_base = AGMSStabilityBands.compute_band()
    print(f"Baseline Band: {res_base['band']}")
    
    with open(outputs_dir / "day_25_baseline_green.txt", "w") as f:
        f.write(json.dumps(res_base, indent=2))
        
    if res_base['band'] != "GREEN":
         print("FAIL: Baseline should be GREEN for score 95/drift 0")
    else:
         print("PASS: Baseline GREEN confirmed.")
    
    # 2. FORCED STORM (ORANGE/RED)
    print("\n[2] Forced Storm (High Drift)...")
    
    # Mock Storm
    # High Drift = 10 (>= 5 is Orange)
    # Score = 75 (> 70 is not Red, but close)
    atomic_write_json(str(p_pat.relative_to(root)), {"total_drift_events": 10})
    atomic_write_json(str(p_coh.relative_to(root)), {"score": 75})
    
    res_storm = AGMSStabilityBands.compute_band()
    print(f"Storm Band: {res_storm['band']}")
    print(f"Reasons: {res_storm['reasons']}")
    
    with open(outputs_dir / "day_25_forced_storm.txt", "w") as f:
        f.write(json.dumps(res_storm, indent=2))
        
    if res_storm['band'] != "ORANGE":
         print("FAIL: Should be ORANGE for drift 10")
    else:
         print("PASS: Storm detected as ORANGE.")
         
    # 3. CRITICAL FAILURE (RED)
    print("\n[3] Forced Critical (Low Coherence)...")
    atomic_write_json(str(p_coh.relative_to(root)), {"score": 60}) # <= 70 is RED
    
    res_red = AGMSStabilityBands.compute_band()
    print(f"Critical Band: {res_red['band']}")
    
    if res_red['band'] != "RED":
         print("FAIL: Should be RED for coherence 60")
    else:
         print("PASS: Critical detected as RED.")

    # 4. WAR ROOM CHECK
    print("\n[4] War Room Integration...")
    dashboard = WarRoom.get_dashboard()
    intel_surface = dashboard["modules"].get("agms", {}).get("intelligence", {})
    band_info = intel_surface.get("stability_band")
    
    print(f"Band INFO Visible: {band_info is not None}")
    if band_info:
        print(f"Current Band in War Room: {band_info.get('band')}")
    
    with open(outputs_dir / "day_25_war_room_band.txt", "w") as f:
         f.write(json.dumps(band_info, indent=2))
         
    # Cleanup
    if p_pat.exists(): os.remove(p_pat)
    if p_coh.exists(): os.remove(p_coh)
    
    if p_pat_bak.exists(): shutil.move(str(p_pat_bak), str(p_pat))
    if p_coh_bak.exists(): shutil.move(str(p_coh_bak), str(p_coh))

    print("\n=== VERIFICATION COMPLETE ===")

if __name__ == "__main__":
    run_verification()
