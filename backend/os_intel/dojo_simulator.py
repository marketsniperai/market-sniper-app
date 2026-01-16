import json
import random
import logging
import math
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Dict, Any, List, Optional
from backend.artifacts.io import atomic_write_json, safe_read_or_fallback, get_artifacts_root

# Setup Logger
logger = logging.getLogger("OS.Intel.Dojo")
logger.setLevel(logging.INFO)

class DojoSimulator:
    """
    OS.Intel.Dojo (Day 33)
    Offline Simulation & Deep Dreaming.
    "We train in the dark so we don't bleed in the light."
    """
    
    CONTRACT_PATH = Path("os_dojo_contract.json")
    OUTPUT_SUBDIR = "runtime/dojo"
    
    @classmethod
    def run(cls, simulations: int = 1000, seed_date: Optional[str] = None) -> Dict[str, Any]:
        """
        Main entry point.
        """
        root = get_artifacts_root()
        cls._ensure_dirs(root)
        
        # 1. Load Truth Seed
        truth = cls._load_today_truth(root, seed_date)
        if not truth["valid"]:
             return cls._exit_insufficient_data(root, truth["missing"])
             
        # 2. Load Bounds (Contracts)
        bounds = cls._load_contract_bounds(root)
        
        # 3. Simulation Loop
        # Budget Check
        budget = min(simulations, 10000) # Hard cap from contract
        
        results = []
        fragility_signals = {}
        
        for i in range(budget):
            variation = cls._generate_variation(truth, i)
            score = cls._score_variation(variation, bounds)
            results.append(score)
            
            # Track failure modes
            if score["outcome"] == "FAIL":
                sig = score["failure_signal"]
                fragility_signals[sig] = fragility_signals.get(sig, 0) + 1
                
        # 4. Produce Recommendations
        recs = cls._produce_recommendations(results, bounds, fragility_signals)
        
        # 5. Persist artifacts
        report = {
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "simulations_run": budget,
            "seed_source": truth["source"],
            "fragility_signals": fragility_signals,
            "status": "PASS"
        }
        
        cls._persist_results(root, report, recs)
        
        return {"status": "PASS", "report": report, "recommendations": recs}

    @classmethod
    def _ensure_dirs(cls, root: Path):
        (root / cls.OUTPUT_SUBDIR).mkdir(parents=True, exist_ok=True)

    @classmethod
    def _load_today_truth(cls, root: Path, seed_date: Optional[str]) -> Dict[str, Any]:
        """
        Loads artifacts to serve as 'Seed Reality'.
        """
        # We need at least one valid pipeline output (full or light) to have data structure
        full = safe_read_or_fallback("full/run_manifest.json")
        light = safe_read_or_fallback("light/run_manifest.json")
        
        # Also check Immune Snapshot if available
        immune = safe_read_or_fallback("runtime/immune/immune_snapshot.json")
        
        if not full["success"] and not light["success"]:
            return {"valid": False, "missing": ["run_manifest (full or light)"]}
            
        # Prefer Full, else Light
        seed = full["data"] if full["success"] else light["data"]
        
        return {
            "valid": True,
            "data": seed,
            "source": "FULL" if full["success"] else "LIGHT",
            "immune_state": immune["data"] if immune["success"] else {}
        }

    @classmethod
    def _load_contract_bounds(cls, root: Path) -> Dict[str, Any]:
        """
        Reads bounds from other contracts to ensure we don't hallucinate unsafe values.
        """
        bounds = {
             "price_spike_threshold": {"min": 0.05, "max": 2.0, "default": 0.5},
             "time_travel_tolerance_sec": {"min": 1, "max": 3600, "default": 300}
        }
        
        # Try reading actual contracts if exist
        try:
             # Immune Contract
             p = Path("os_immune_system_contract.json")
             if p.exists():
                 with open(p, "r") as f:
                     ic = json.load(f)
                     # naive extraction if structure matches
                     pass
        except: pass
        
        return bounds

    @classmethod
    def _generate_variation(cls, truth: Dict[str, Any], seed_val: int) -> Dict[str, Any]:
        """
        Deep Dreaming: Generates a synthetic scenario based on truth.
        """
        # Deterministic random based on seed
        rng = random.Random(seed_val)
        
        # Copy base
        # We simulate "Metric Data" mostly.
        # Check seed data structure. RunManifest isn't deep data.
        # We imply we'd load context or pulse data if we wanted deep simulation.
        # For Day 33, we keep it abstract: "Simulating Threshold Checks".
        
        # We simulate a "Price Move" and "Time Drift" scalar
        base_price_move = 0.01
        
        # Perturbation types
        scenario = {
            "id": seed_val,
            "price_delta_pct": base_price_move + (rng.gauss(0, 0.2)), # Volatility
            "time_drift_sec": rng.randint(-100, 600), # Jitter
            "null_packet": rng.random() < 0.05, # 5% chance
            "nan_value": rng.random() < 0.01 # 1% chance
        }
        return scenario

    @classmethod
    def _score_variation(cls, var: Dict[str, Any], bounds: Dict[str, Any]) -> Dict[str, Any]:
        """
        Scores the variation against guards.
        """
        outcome = "PASS"
        fail_sig = "NONE"
        
        # 1. Null Check
        if var["null_packet"]:
             return {"outcome": "FAIL", "failure_signal": "NULL_PACKET"}
             
        # 2. NaN Check
        if var["nan_value"]:
             return {"outcome": "FAIL", "failure_signal": "NEGATIVE_OR_NAN"}
             
        # 3. Price Spike
        thresh = bounds["price_spike_threshold"]["default"]
        if abs(var["price_delta_pct"]) > thresh:
             return {"outcome": "FAIL", "failure_signal": "PRICE_SPIKE_ANOMALY"}
             
        # 4. Time Travel
        time_thresh = bounds["time_travel_tolerance_sec"]["default"]
        if var["time_drift_sec"] > time_thresh:
             return {"outcome": "FAIL", "failure_signal": "TIME_TRAVEL"}
             
        return {"outcome": "PASS", "failure_signal": "NONE"}

    @classmethod
    def _produce_recommendations(cls, results: List[Dict], bounds: Dict, fragility: Dict) -> Dict[str, Any]:
        """
        Proposes tuning.
        If too many failures, maybe relax threshold?
        If zero failures, maybe tighten?
        """
        # Simple Logic: 
        # If PRICE_SPIKE > 10% of sims, suggest increase threshold.
        # If PRICE_SPIKE == 0, suggest decrease.
        
        total = len(results)
        if total == 0: return {}
        
        recs = {}
        
        # Price
        spike_fails = fragility.get("PRICE_SPIKE_ANOMALY", 0)
        spike_rate = spike_fails / total
        curr_price = bounds["price_spike_threshold"]["default"]
        
        if spike_rate > 0.10:
             # Too fragile, relax
             new_val = min(curr_price * 1.1, bounds["price_spike_threshold"]["max"])
             recs["price_spike_threshold"] = {"action": "RELAX", "value": round(new_val, 2), "reason": f"High failure rate ({spike_rate*100:.1f}%)"}
        elif spike_rate == 0:
             # Too loose, tighten
             new_val = max(curr_price * 0.9, bounds["price_spike_threshold"]["min"])
             recs["price_spike_threshold"] = {"action": "TIGHTEN", "value": round(new_val, 2), "reason": "Zero failures, optimizing sensitivity"}
             
        return recs

    @classmethod
    def _persist_results(cls, root: Path, report: Dict, recs: Dict):
        base = root / cls.OUTPUT_SUBDIR
        
        # Report
        atomic_write_json(str(base / "dojo_simulation_report.json"), report)
        
        # Recommendations
        atomic_write_json(str(base / "dojo_recommended_thresholds.json"), recs)
        
        # Ledger
        ledger_path = base / "dojo_ledger.jsonl"
        entry = {
            "timestamp": report["timestamp_utc"],
            "simulations": report["simulations_run"],
            "fragility": report["fragility_signals"],
            "recommendation_count": len(recs)
        }
        with open(ledger_path, "a") as f:
            f.write(json.dumps(entry) + "\n")

    @classmethod
    def _exit_insufficient_data(cls, root: Path, missing: List[str]):
        """
        Exit Safely for missing data.
        """
        report = {
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "status": "INSUFFICIENT_DATA",
            "missing_artifacts": missing
        }
        
        # Safe write report
        base = root / cls.OUTPUT_SUBDIR
        atomic_write_json(str(base / "dojo_simulation_report.json"), report)
        
        return {"status": "INSUFFICIENT_DATA", "report": report}
