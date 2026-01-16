import os
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List, Optional
from backend.artifacts.io import atomic_write_json, get_artifacts_root, safe_read_or_fallback, append_to_ledger

# TITANIUM LAW: AGMS TUNES SENSITIVITY. NO EXECUTION.
NO_EXECUTION_GUARD = True

# LOAD CONTRACT DEFAULTS (SIMULATED FOR SPEED, IDEALLY LOAD JSON)
CONTRACT_DEFAULTS = {
    "stale_light_seconds": {"default": 900, "min": 300, "max": 1800},
    "stale_full_seconds": {"default": 93600, "min": 3600, "max": 172800},
    "misfire_threshold_seconds": {"default": 93600, "min": 3600, "max": 172800}
}

class AGMSDynamicThresholds:
    """
    Day 24: AGMS Dynamic Thresholds.
    Tunes system sensitivity based on Drift and Coherence.
    
    Responsibilities:
    1. Read Intelligence (Patterns, Coherence).
    2. Compute Multiplier (Tighten/Relax).
    3. Apply to Defaults + Clamp (Min/Max).
    4. Publish Active Thresholds.
    """
    
    AGMS_ROOT = "runtime/agms"
    
    @staticmethod
    def compute_thresholds() -> Dict[str, Any]:
        """
        Main entry point.
        """
        assert NO_EXECUTION_GUARD is True, "AGMS MUST NOT EXECUTE"
        
        root = get_artifacts_root()
        now = datetime.now(timezone.utc)
        
        # 1. READ INTELLIGENCE
        pat_res = safe_read_or_fallback("runtime/agms/agms_patterns.json")
        coh_res = safe_read_or_fallback("runtime/agms/agms_coherence_snapshot.json")
        
        patterns = pat_res.get("data", {})
        coherence = coh_res.get("data", {})
        
        # 2. DETERMINE MULTIPLIER
        multiplier = 1.0
        reason = "NOMINAL"
        
        # Logic: Tighten if Drift is frequent
        total_drift = patterns.get("total_drift_events", 0)
        coherence_score = coherence.get("score", 100)
        
        if total_drift > 5 or coherence_score < 80:
            multiplier = 0.8 # Tighten by 20%
            reason = "HIGH_DRIFT_DETECTED"
        elif total_drift > 2:
            multiplier = 0.9 # Tighten by 10%
            reason = "MODERATE_DRIFT"
            
            reason = "MODERATE_DRIFT"
            
        # 3. COMPUTE VALUES
        thresholds = {}
        
        # Day 33.1: Check for Runtime Tuning Overrides
        overrides = AGMSDynamicThresholds._load_runtime_overrides(root, now)
        override_active = False
        
        for key, spec in CONTRACT_DEFAULTS.items():
            # Priority: Override > Multiplier > Default
            if key in overrides:
                val = overrides[key]
                thresholds[key] = val
                override_active = True
            else:
                base = spec["default"]
                val = int(base * multiplier)
                
                # Clamp
                if val < spec["min"]: val = spec["min"]
                if val > spec["max"]: val = spec["max"]
                
                thresholds[key] = val
                
        if override_active:
            reason = f"RUNTIME_TUNING_ACTIVE ({reason})"
            
        result = {
            "timestamp_utc": now.isoformat(),
            "multiplier": multiplier,
            "reason": reason,
            "thresholds": thresholds
        }
        
        # 4. PERSIST
        AGMSDynamicThresholds._persist_artifacts(root, result, now)
        
        return result

    @staticmethod
    def _persist_artifacts(root: Path, result: Dict[str, Any], now: datetime):
        agms_dir = root / AGMSDynamicThresholds.AGMS_ROOT
        
        # 1. Active Thresholds File (The Source of Truth for Consumers)
        atomic_write_json(str(agms_dir / "agms_dynamic_thresholds.json"), result)
        
        # 2. Ledger
        entry = {
            "timestamp_utc": now.isoformat(),
            "multiplier": result["multiplier"],
            "reason": result["reason"],
            "changes": result["thresholds"]
        }
        append_to_ledger("runtime/agms/agms_thresholds_ledger.jsonl", entry)

    @staticmethod
    def _load_runtime_overrides(root: Path, now: datetime) -> Dict[str, Any]:
        """
        Day 33.1: Loads approved runtime tuning values.
        Validation: Must be fresh (< 24h).
        """
        res = safe_read_or_fallback("runtime/tuning/applied_thresholds.json")
        if not res["success"]: return {}
        
        data = res["data"]
        try:
            meta = data.get("meta", {})
            applied_at = datetime.fromisoformat(meta.get("applied_at"))
            # Freshness Check: 24h
            if (now - applied_at).total_seconds() > 86400:
                return {}
            
            return data.get("overrides", {})
        except:
            return {}
