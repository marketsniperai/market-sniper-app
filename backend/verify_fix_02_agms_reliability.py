import sys
from pathlib import Path
import json
import logging

# Add project root to sys.path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from backend.os_intel.agms_foundation import AGMSFoundation
from backend.os_intel.agms_intelligence import AGMSIntelligence
from backend.os_intel.projection_orchestrator import ProjectionOrchestrator
from backend.artifacts.io import get_artifacts_root

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("VERIFY_FIX_02")

def verify_fix():
    print(">>> D47.FIX.02: AGMS Reliability Scoreboard Verification <<<")
    
    # 1. Simulate Projection Calls (Generating Observations)
    print("\n[1] Simulating Projection Calls...")
    
    # A. Global Cache Simulated
    # We can't easily force simulate specific cache hits without mocking, 
    # but we can call record directly to ensure ledger works, OR populate caches.
    # For speed and safety, we will direct-call the standard orchestration
    # knowing that it will hit COMPUTED_PIPELINE if cache is empty.
    
    symbols = ["SPY", "TSLA", "AAPL"]
    for s in symbols:
        print(f" -> Invoking ProjectionOrchestrator for {s}...")
        try:
             res = ProjectionOrchestrator.build_projection_report(s, "DAILY")
             print(f"    Result State: {res.get('state')} (Source: {res.get('tactical', {}).get('watch', [''])[0]})")
        except Exception as e:
             print(f"    Error: {e}")
             
    # 2. Check Ledger
    root = get_artifacts_root()
    ledger_path = root / "runtime/agms/reliability_ledger.jsonl"
    print(f"\n[2] Checking Ledger at {ledger_path}...")
    
    if not ledger_path.exists():
        print("FAIL: Ledger not found!")
        return
        
    lines = []
    with open(ledger_path, "r") as f:
        lines = f.readlines()
        
    print(f" -> Found {len(lines)} entries.")
    if len(lines) == 0:
        print("FAIL: Ledger is empty!")
        return
        
    last_entry = json.loads(lines[-1])
    print(f" -> Last Entry: {json.dumps(last_entry, indent=2)}")
    
    if "state" not in last_entry or "source" not in last_entry:
        print("FAIL: Ledger entry missing required fields.")
        return

    # 3. Trigger AGMS Intelligence (Analysis)
    print("\n[3] Triggering AGMS Intelligence...")
    try:
        intel_res = AGMSIntelligence.generate_intelligence()
        print(" -> Logic Executed.")
        
        # Check for reliability block
        snapshot_path = root / "runtime/agms/agms_coherence_snapshot.json"
        with open(snapshot_path, "r") as f:
            snap = json.load(f)
            
        print("\n[4] verifying Snapshot Artifact...")
        if "reliability" in snap:
            print("SUCCESS: 'reliability' key found in snapshot.")
            print(json.dumps(snap["reliability"], indent=2))
        else:
            print("FAIL: 'reliability' key MISSING in snapshot!")
            
    except Exception as e:
        print(f"FAIL: AGMS Intelligence crashed: {e}")
        
    print("\n>>> VERIFICATION COMPLETE <<<")

if __name__ == "__main__":
    verify_fix()
