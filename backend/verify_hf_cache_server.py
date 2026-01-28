import sys
import os
import json
import time

# Add repo root to path
sys.path.append(os.getcwd())

from backend.os_intel.projection_orchestrator import ProjectionOrchestrator
from backend.os_ops.hf_cache_server import OnDemandCacheServer

def verify_cache():
    print("--- VERIFYING HF CACHE SERVER ---")
    
    ticker = "TEST_CACHE"
    timeframe = "DAILY"
    
    # Clean previous run
    key = OnDemandCacheServer._generate_key(ticker, timeframe)
    cache_path = OnDemandCacheServer.CACHE_DIR / key
    if cache_path.exists():
        os.remove(cache_path)
        print("Cleaned previous cache artifact.")
        
    # 1. First Run (MISS)
    print("\n1. Running Orchestrator (Expected MISS)...")
    res1 = ProjectionOrchestrator.build_projection_report(ticker, timeframe)
    
    print(f"Orchestrator Result Type: {type(res1)}")
    if res1 is None:
        print("[FAIL] Orchestrator returned None.")
        return

    if res1.get("cache_hit") is True:
        print("[FAIL] First run reported cache_hit=True")
        return
        
    if not cache_path.exists():
        print("[FAIL] Cache artifact not created after run.")
        return
    else:
        print("[PASS] Cache artifact created.")
        
    # 2. Second Run (HIT)
    print("\n2. Running Orchestrator (Expected HIT)...")
    res2 = ProjectionOrchestrator.build_projection_report(ticker, timeframe)
    
    if res2.get("cache_hit") is not True:
        print("[FAIL] Second run did not report cache_hit=True")
        return
    else:
        print("[PASS] Cache hit confirmed.")
        
    # 3. Validation
    # Timestamps should be (roughly) same if cached, except for cached_at_server injection
    t1 = res1.get("asOfUtc")
    t2 = res2.get("asOfUtc")
    
    if t1 == t2:
        print("[PASS] Timestamps match (Source Truth preserved).")
    else:
        print(f"[FAIL] Timestamp drift! T1: {t1}, T2: {t2}")
        
    print("\n--- HF CACHE VERIFIED ---")

if __name__ == "__main__":
    verify_cache()
