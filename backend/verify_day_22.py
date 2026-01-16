import os
import sys
import json
import shutil
from pathlib import Path

# Add repo root to path
sys.path.append(os.getcwd())

from backend.agms_shadow_recommender import AGMSShadowRecommender
from backend.war_room import WarRoom
from backend.artifacts.io import get_artifacts_root, atomic_write_json

def run_verification():
    print("=== DAY 22 VERIFICATION SUITE ===")
    
    outputs_dir = Path("outputs/runtime/day_22")
    os.makedirs(outputs_dir, exist_ok=True)
    root = get_artifacts_root()
    p_patterns = root / "runtime/agms/agms_patterns.json"
    p_patterns_bak = root / "runtime/agms/agms_patterns.json.bak_verify"
    
    # 1. BASELINE RUN
    print("\n[1] Baseline Shadow Recommender...")
    # Run Pattern Engine first to ensure fresh state if needed, but we assume D21 art exists
    # Just run Recommender
    snap_base = AGMSShadowRecommender.generate_suggestions()
    count_base = snap_base["suggestion_count"]
    print(f"Baseline Suggestions: {count_base}")
    
    with open(outputs_dir / "day_22_baseline.txt", "w") as f:
        f.write(json.dumps(snap_base, indent=2))
        
    # 2. FORCED PATTERN (Inject MISSING_LIGHT_MANIFEST)
    print("\n[2] Forced Suggestion Simulation...")
    
    if p_patterns.exists():
        shutil.move(str(p_patterns), str(p_patterns_bak))
        
    try:
        # Mock Patterns Artifact
        mock_patterns = {
            "top_drift_types": [
                {"type": "MISSING_LIGHT_MANIFEST", "count": 10, "percentage": 50.0},
                {"type": "GARBAGE_FOUND", "count": 5, "percentage": 25.0}
            ],
            "unstable_modules": []
        }
        atomic_write_json(str(p_patterns.relative_to(root)), mock_patterns)
        
        # Run Recommender
        snap_forced = AGMSShadowRecommender.generate_suggestions()
        suggestions = snap_forced["suggestions"]
        
        # Verify Mappings
        mapped_ids = [s["mapped_playbook_id"] for s in suggestions]
        print(f"Mapped Playbooks: {mapped_ids}")
        
        expected = ["PB-T1-MISFIRE-LIGHT", "PB-T1-GARBAGE-FOUND"]
        missing = [ex for ex in expected if ex not in mapped_ids]
        
        if missing:
             print(f"FAIL: Missing expected suggestions: {missing}")
        else:
             print("PASS: Detected and mapped correctly.")
             
        # Check Safety Note
        safety = suggestions[0].get("safety_note")
        print(f"Safety Note: {safety}")
        if safety != "SUGGEST-ONLY":
             print("FAIL: Safety note invalid.")
             
        with open(outputs_dir / "day_22_forced_pattern.txt", "w") as f:
            f.write(json.dumps(snap_forced, indent=2))
            
    finally:
        # Restore Patterns
        if p_patterns.exists():
            os.remove(p_patterns)
        if p_patterns_bak.exists():
            shutil.move(str(p_patterns_bak), str(p_patterns))
            print("Patterns Artifact Restored.")

    # 3. WAR ROOM CHECK
    print("\n[3] War Room Integration...")
    dashboard = WarRoom.get_dashboard()
    intel_surface = dashboard["modules"].get("agms", {}).get("intelligence", {})
    shadow_sug = intel_surface.get("shadow_suggestions", [])
    print(f"War Room Shadow Suggestions Count: {len(shadow_sug)}")
    
    if "shadow_suggestions" not in intel_surface:
        print("FAIL: Shadow Suggestions missing from War Room.")
        sys.exit(1)

    # 4. SAFETY CHECK
    print("\n[4] Zero Side Effects...")
    is_safe = AGMSShadowRecommender.verify_no_side_effects()
    print(f"Guard Check: {is_safe}")
    
    with open(outputs_dir / "day_22_safety_check.txt", "w") as f:
         f.write(f"Guard: {is_safe}")

    print("\n=== VERIFICATION COMPLETE ===")

if __name__ == "__main__":
    run_verification()
