
import json
import time
from backend.os_intel.projection_orchestrator import ProjectionOrchestrator
from backend.os_ops.computation_ledger import ComputationLedger
from backend.os_ops.hf_cache_server import OnDemandCacheServer

def run_test():
    ticker = "TEST_HF32"
    timeframe = "DAILY"
    
    # 1. Clear State (Ledger needs manual purge or we assume fresh ticker)
    # Just use a unique ticker for the test run.
    print("[TEST] Run 1: Should Compute")
    res1 = ProjectionOrchestrator.build_projection_report(ticker, timeframe)
    
    assert res1.get("policy_block") is None, "Run 1 should NOT be blocked"
    
    # Verify Ledger Updated
    has_run = ComputationLedger.has_run_today(ticker, timeframe)
    assert has_run is True, "Ledger should record Run 1"
    
    # 2. Run 2: Should Block and Serve Cache
    print("[TEST] Run 2: Should Block (Policy)")
    res2 = ProjectionOrchestrator.build_projection_report(ticker, timeframe)
    
    if res2.get("policy_block"):
        print("[SUCCESS] Policy Block Triggered.")
        print(f"Source: {res2.get('managed_by_policy')}")
    else:
        print("[FAILURE] Policy Block MISSED.")
        # If cache was missed, it might have computed. Check logs.
        
    # Verify Metadata
    assert res2.get("managed_by_policy") == "HF32_DAILY_LIMIT"
    assert res2.get("cache_hit") is True

    # 3. Output Evidence
    with open("outputs/proofs/hf32_cost_policy_on_demand/02_sample_first_run.json", "w") as f:
        json.dump(res1, f, indent=2)
        
    with open("outputs/proofs/hf32_cost_policy_on_demand/03_sample_second_run_policy_block.json", "w") as f:
        json.dump(res2, f, indent=2)

if __name__ == "__main__":
    try:
        run_test()
        print("[TEST] Verification PASSED.")
    except Exception as e:
        print(f"[TEST] Verification FAILED: {e}")
        raise e
