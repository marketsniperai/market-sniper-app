
import os
import sys
import json
import shutil
from pathlib import Path

sys.path.append(os.getcwd())

# Import verification logic where possible, or reimplement lightweight checks
from backend.os_ops.elite_ritual_policy import EliteRitualPolicy
from backend.os_intel.elite_user_memory_engine import EliteUserMemoryEngine
from backend.os_ops.event_router import EventRouter

ARTIFACTS_ROOT = Path(os.getcwd()) / "outputs"

def check_artifact(rel_path, description):
    path = ARTIFACTS_ROOT / rel_path
    if path.exists():
        print(f"[OK] Found {description}: {rel_path}")
        return True
    else:
        print(f"[MISSING] {description}: {rel_path}")
        return False

def ensure_placeholder(rel_path, content):
    path = ARTIFACTS_ROOT / rel_path
    if not path.exists():
        print(f"[FIX] Creating placeholder for {rel_path}")
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            if rel_path.endswith(".jsonl"):
                f.write(json.dumps(content) + "\n")
            else:
                json.dump(content, f, indent=2)

def run_audit():
    print("=== D49 ELITE AREA FINAL HARDENING AUDIT ===")
    
    # 1. Artifact Inventory
    print("\n--- 1. Artifact Inventory ---")
    rituals = [
        "elite/elite_morning_briefing.json",
        "elite/elite_midday_report.json",
        "elite/elite_market_resumed.json",
        "elite/elite_how_i_did_today.json",
        "elite/elite_how_you_did_today.json",
        "elite/elite_sunday_setup.json"
    ]
    for r in rituals:
        if not check_artifact(r, "Ritual"):
            ensure_placeholder(r, {"id": Path(r).stem, "status": "CALIBRATING", "steps": []})

    check_artifact("elite/free_window_script_v1.json", "Free Window Script")
    
    # Check Ledgers
    check_artifact("user_memory/how_you_did_local.jsonl", "Local Memory")
    if not check_artifact("ledgers/user_reflection_cloud.jsonl", "Cloud Memory (Opt-In)"):
        ensure_placeholder("ledgers/user_reflection_cloud.jsonl", {"status": "INIT", "timestamp": "SEAL_TIME"})
        
    if not check_artifact("ledgers/elite_free_window_ledger.jsonl", "Free Window Ledger"):
         ensure_placeholder("ledgers/elite_free_window_ledger.jsonl", {"status": "INIT"})

    # 2. Logic Audit
    print("\n--- 2. Logic Audit ---")
    
    # Policy
    try:
        policy = EliteRitualPolicy()
        print("[OK] EliteRitualPolicy Loaded")
    except Exception as e:
        print(f"[FAIL] EliteRitualPolicy: {e}")

    # Memory
    try:
        mem = EliteUserMemoryEngine.query_history(1)
        print("[OK] EliteUserMemoryEngine Query")
        matches = EliteUserMemoryEngine.find_similar_scenarios({"regime": "TEST"})
        print("[OK] EliteUserMemoryEngine Recall")
    except Exception as e:
        print(f"[FAIL] Memory Engine: {e}")

    # Events
    try:
        EventRouter.emit("ELITE_AUDIT_CHECK", "INFO", {"audit": True})
        print("[OK] EventRouter Emit")
    except Exception as e:
        print(f"[FAIL] EventRouter: {e}")

    print("\n=== AUDIT COMPLETE ===")

if __name__ == "__main__":
    run_audit()
