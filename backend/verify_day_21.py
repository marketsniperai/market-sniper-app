import os
import sys
import json
import shutil
import time
from pathlib import Path

# Add repo root to path
sys.path.append(os.getcwd())

from backend.agms_intelligence import AGMSIntelligence
from backend.war_room import WarRoom
from backend.artifacts.io import get_artifacts_root, append_to_ledger

def run_verification():
    print("=== DAY 21 VERIFICATION SUITE ===")
    
    outputs_dir = Path("outputs/runtime/day_21")
    os.makedirs(outputs_dir, exist_ok=True)
    root = get_artifacts_root()
    agms_ledger = root / "runtime/agms/agms_ledger.jsonl"
    agms_ledger_bak = root / "runtime/agms/agms_ledger.jsonl.bak_verify"
    
    # 1. BASELINE RUN
    print("\n[1] Baseline Intelligence Run...")
    intel_base = AGMSIntelligence.generate_intelligence()
    score_base = intel_base["coherence"]["score"]
    print(f"Baseline Coherence: {score_base}")
    print(f"Baseline Patterns: {len(intel_base['patterns']['top_drift_types'])}")
    
    with open(outputs_dir / "day_21_intelligence_baseline.txt", "w") as f:
        f.write(json.dumps(intel_base, indent=2))
        
    # 2. FORCED PATTERN (Inject 10 missings)
    print("\n[2] Forced Pattern (Simulated Drift)...")
    
    # Backup real ledger
    if agms_ledger.exists():
        shutil.move(str(agms_ledger), str(agms_ledger_bak))
        
    try:
        # Create fake history
        fake_entries = []
        for i in range(10):
            fake_entries.append({
                "timestamp_utc": "2026-01-01T12:00:00Z",
                "drift_deltas": ["MISSING_LIGHT_MANIFEST", "LOCK_STUCK_1H"],
                "drift_score": 2
            })
        
        # Write fake ledger
        for e in fake_entries:
            append_to_ledger("runtime/agms/agms_ledger.jsonl", e)
            
        # Run Intelligence
        intel_forced = AGMSIntelligence.generate_intelligence()
        
        # Verify
        patterns = intel_forced["patterns"]
        top_drifts = [p["type"] for p in patterns["top_drift_types"]]
        print(f"Top Drifts Detected: {top_drifts}")
        
        coherence = intel_forced["coherence"]
        print(f"Forced Coherence Score: {coherence['score']}")
        print(f"Explanation: {coherence['explanation']}")
        
        with open(outputs_dir / "day_21_intelligence_forced.txt", "w") as f:
            f.write(json.dumps(intel_forced, indent=2))
            
        if "MISSING_LIGHT_MANIFEST" not in top_drifts:
            print("FAIL: Did not detect forced drift pattern.")
        
        if coherence["score"] >= score_base and score_base > 0:
             print("FAIL: Coherence score did not drop with forced drift.")
             
    finally:
        # Restore real ledger
        if agms_ledger.exists():
            os.remove(agms_ledger) # Remove fake
        if agms_ledger_bak.exists():
            shutil.move(str(agms_ledger_bak), str(agms_ledger))
            print("Ledger Restored.")

    # 3. WAR ROOM CHECK
    print("\n[3] War Room Integration...")
    dashboard = WarRoom.get_dashboard()
    intel_surface = dashboard["modules"].get("agms", {}).get("intelligence", {})
    print(f"War Room Coherence: {intel_surface.get('coherence', {}).get('score')}")
    
    if "coherence" not in intel_surface:
        print("FAIL: Intelligence missing from War Room.")
        sys.exit(1)

    print("\n=== VERIFICATION COMPLETE ===")

if __name__ == "__main__":
    run_verification()
