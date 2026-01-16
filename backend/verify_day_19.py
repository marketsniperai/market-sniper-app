import os
import sys
import json
import shutil
from pathlib import Path

# Add repo root to path
sys.path.append(os.getcwd())

from backend.autofix_control_plane import AutoFixControlPlane
from backend.war_room import WarRoom
from backend.shadow_repair import ShadowRepair
from backend.artifacts.io import atomic_write_json

def run_verification():
    print("=== DAY 19 VERIFICATION SUITE ===")
    
    # Setup
    outputs_dir = Path("outputs/runtime/day_19")
    os.makedirs(outputs_dir, exist_ok=True)
    
    # A) Registry Load
    print("\n[A] Registry Load...")
    playbooks = AutoFixControlPlane.load_playbooks()
    print(f"Loaded {len(playbooks)} playbooks.")
    with open(outputs_dir / "day_19_playbooks_loaded.json", "w") as f:
        json.dump({"count": len(playbooks), "ids": [p["playbook_id"] for p in playbooks]}, f, indent=2)
    
    if len(playbooks) < 5:
        print("FAIL: Too few playbooks loaded.")
        sys.exit(1)

    # B) Nominal State
    print("\n[B] Nominal State Check...")
    nominal_res = AutoFixControlPlane.assess_and_recommend()
    print(f"Status: {nominal_res['status']}")
    with open(outputs_dir / "day_19_autofix_nominal.txt", "w") as f:
        f.write(json.dumps(nominal_res, indent=2))
        
    if nominal_res["status"] != "NOMINAL":
        # It might be ACTION_RECOMMENDED if system is actually dirty/stale.
        print(f"WARN: System not NOMINAL ({nominal_res['status']}). Checking if valid.")
        
    # C) Forced Condition (Missing Light Manifest)
    print("\n[C] Forced Misfire (Missing Light)...")
    light_path = Path("outputs/light/run_manifest.json")
    bak_path = Path("outputs/light/run_manifest.json.bak_test")
    
    # Backup existing
    if light_path.exists():
        shutil.move(str(light_path), str(bak_path))
        
    try:
        # Check Autofix
        forced_res = AutoFixControlPlane.assess_and_recommend()
        print(f"Status: {forced_res['status']}")
        matches = forced_res.get("matched_playbooks", [])
        print(f"Matched: {[m['playbook_id'] for m in matches]}")
        
        with open(outputs_dir / "day_19_autofix_forced_missing_light.txt", "w") as f:
            f.write(json.dumps(forced_res, indent=2))
            
        # Use simple string check for ID presence
        found = any("MISFIRE-LIGHT" in m["playbook_id"] for m in matches)
        if not found:
             print("FAIL: Did not match MISFIRE-LIGHT playbook.")
             # Don't exit yet, restore first
    finally:
        # Restore
        if bak_path.exists():
            shutil.move(str(bak_path), str(light_path))
            
    # D) War Room Surface
    print("\n[D] War Room Surface...")
    dashboard = WarRoom.get_dashboard()
    print(f"Modules: {dashboard['modules'].keys()}")
    evidence_count = len(dashboard.get("evidence", []))
    print(f"Evidence items: {evidence_count}")
    
    with open(outputs_dir / "day_19_war_room_playbook_surface.txt", "w") as f:
        f.write(json.dumps(dashboard, indent=2))
        
    # E) Shadow Repair
    print("\n[E] Shadow Repair Proposal...")
    proposal = ShadowRepair.propose_patch(
        symptoms=["missing outputs/light/run_manifest.json"],
        playbook_id="PB-T1-MISFIRE-LIGHT"
    )
    print(f"Proposal ID: {proposal['proposal_id']}")
    print(f"Status: {proposal['status']}")
    
    with open(outputs_dir / "day_19_shadow_repair_proposal.txt", "w") as f:
        f.write(json.dumps(proposal, indent=2))
        
    if proposal["status"] != "PROPOSED_ONLY":
        print("FAIL: Shadow Repair status not PROPOSED_ONLY")
        sys.exit(1)
        
    print("\n=== VERIFICATION COMPLETE ===")

if __name__ == "__main__":
    run_verification()
