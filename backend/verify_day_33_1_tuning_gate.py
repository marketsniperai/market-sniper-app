import json
import logging
import time
import shutil
from pathlib import Path
from backend.os_ops.tuning_gate import TuningGate
from backend.os_intel.agms_dynamic_thresholds import AGMSDynamicThresholds
from backend.artifacts.io import atomic_write_json, get_artifacts_root

# Setup Logger
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("Day33_1_Verify")

OUTPUT_DIR = Path("backend/outputs/runtime/day_33_1")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
RUNTIME_TUNING = Path("backend/outputs/runtime/tuning")

def main():
    results = {
        "status": "UNKNOWN",
        "tests": {},
        "timestamp": time.time()
    }
    
    try:
        logger.info("--- Starting Day 33.1 Verification: Tuning Gate ---")
        root = get_artifacts_root()
        
        # 1. Clean Slate
        if RUNTIME_TUNING.exists():
            shutil.rmtree(RUNTIME_TUNING)
        (root / "runtime/dojo").mkdir(parents=True, exist_ok=True)
            
        # 2. Test INSUFFICIENT_DATA (No Recs)
        logger.info("Test 1: Missing Recs...")
        res = TuningGate.run_tuning_cycle()
        if res["status"] == "SKIPPED":
            results["tests"]["missing_recs"] = "PASSED"
        else:
            results["tests"]["missing_recs"] = f"FAILED: Got {res['status']}"
            
        # 3. Test Kill Switch (Enabled=False but Recs Present)
        # Mock Recs
        mock_recs = {
            "price_spike_threshold": {"value": 0.06},
            "time_travel_tolerance_sec": {"value": 300}
        }
        atomic_write_json(str(root / "runtime/dojo/dojo_recommended_thresholds.json"), mock_recs)
        
        logger.info("Test 2: Kill Switch (Default False)...")
        res = TuningGate.run_tuning_cycle(force_enable=False)
        if res["status"] == "DENIED_KILL_SWITCH":
            results["tests"]["kill_switch_active"] = "PASSED"
        else:
            results["tests"]["kill_switch_active"] = f"FAILED: Got {res['status']}"
            
        # 4. Test Bounds Clamping & Approval (Force Enable=True)
        # Mock Out of Bounds Recs
        bad_recs = {
            "price_spike_threshold": {"value": 10.0}, # Max 2.0
            "time_travel_tolerance_sec": {"value": -50} # Min 1
        }
        atomic_write_json(str(root / "runtime/dojo/dojo_recommended_thresholds.json"), bad_recs)
        
        logger.info("Test 3: Bounds Clamping & Apply...")
        res = TuningGate.run_tuning_cycle(force_enable=True)
        
        if res["status"] == "APPLIED":
             clamped = res["clamped_recs"]
             p_val = clamped["price_spike_threshold"]["value"]
             t_val = clamped["time_travel_tolerance_sec"]["value"]
             
             if p_val == 2.0 and t_val == 1:
                  results["tests"]["bounds_clamping"] = "PASSED"
             else:
                  results["tests"]["bounds_clamping"] = f"FAILED: Expected 2.0/1, Got {p_val}/{t_val}"
                  
             results["tests"]["apply_success"] = "PASSED"
        else:
             results["tests"]["apply_success"] = f"FAILED: {res['status']}"
             results["tests"]["bounds_clamping"] = "SKIPPED"
             
        # 5. Verify Consumer Override
        # We expect applied_thresholds.json to exist now
        logger.info("Test 4: Consumer Override...")
        
        # AGMSDynamicThresholds uses defaults 0.05 - 2.0 not usually mapped to 900s
        # Wait, the contract defaults in AGMS vs Tuning Gate Mock are different keys/units?
        # Tuning Mock used "price_spike_threshold"
        # AGMS uses "stale_light_seconds"
        # Let's inject a relevant key for AGMS
        agms_recs = {
            "stale_light_seconds": {"value": 500}
        }
        atomic_write_json(str(root / "runtime/dojo/dojo_recommended_thresholds.json"), agms_recs)
        TuningGate.run_tuning_cycle(force_enable=True)
        
        # Now verify consumer
        # We need to mock get_artifacts_root or ensure AGMS reads from same place
        # AGMS computes
        computed = AGMSDynamicThresholds.compute_thresholds()
        final_val = computed["thresholds"].get("stale_light_seconds")
        
        if final_val == 500:
             results["tests"]["consumer_override"] = "PASSED"
        else:
             results["tests"]["consumer_override"] = f"FAILED: Expected 500, Got {final_val}"

        # 6. War Room Check
        from backend.os_ops.war_room import WarRoom
        st = WarRoom._get_tuning_status(root)
        if st["applied_active"] and "stale_light_seconds" in st["active_overrides"]:
             results["tests"]["war_room_panel"] = "PASSED"
        else:
             results["tests"]["war_room_panel"] = f"FAILED: {st}"

        # Final Status
        if all(v == "PASSED" for v in results["tests"].values()):
            results["status"] = "PASSED"
        else:
            results["status"] = "FAILED"

    except Exception as e:
        logger.error(f"FATAL: {e}")
        results["status"] = "CRASHED"
        results["error"] = str(e)
        
    with open(OUTPUT_DIR / "day_33_1_verify.json", "w") as f:
        json.dump(results, f, indent=2)
        
    print(json.dumps(results, indent=2))

if __name__ == "__main__":
    main()
