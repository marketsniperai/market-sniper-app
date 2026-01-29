
import json
import sys
import os

# Add parent dir to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.os_intel.projection_orchestrator import ProjectionOrchestrator

def verify_attribution():
    try:
        print("Running ProjectionOrchestrator.build_projection_report directly...")
        data = ProjectionOrchestrator.build_projection_report("SPY", "DAILY")
        
        # Check Root Keys
        if "attribution" not in data:
            print("[FAIL] 'attribution' key missing in payload.")
            sys.exit(1)
            
        attr = data["attribution"]
        
        # Check Sub-Keys
        required = ["generatedAtUtc", "ticker", "timeframe", "source_ladder_used", "inputs_consulted", "rules_fired", "derived_facts", "blur_reasons"]
        for k in required:
            if k not in attr:
                print(f"[FAIL] Missing attribution key: {k}")
                sys.exit(1)
                
        # Valdiate Blur Reasons
        blurs = attr["blur_reasons"]
        if not isinstance(blurs, list):
             print("[FAIL] 'blur_reasons' is not a list.")
             sys.exit(1)
        
        # We expect static policies active
        found_tier_gate = False
        for b in blurs:
            if b.get("reason") == "TierGate":
                found_tier_gate = True
                print(f"   [OK] Found TierGate: {b.get('surface')}")
        
        if not found_tier_gate:
             print("[WARN] No TierGate blur reasons found. (Is this right?)")
             
        print("\n[SUCCESS] Attribution Payload Verified.")
        print(json.dumps(attr, indent=2))
        
    except Exception as e:
        print(f"[ERROR] Request failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    verify_attribution()
