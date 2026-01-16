import os
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List, Optional
from backend.artifacts.io import atomic_write_json, get_artifacts_root, safe_read_or_fallback, append_to_ledger

# TITANIUM LAW: AGMS OBSERVES AND LABELS. NO EXECUTION.
NO_EXECUTION_GUARD = True

class AGMSStabilityBands:
    """
    Day 25: AGMS Stability Bands.
    Translates metric signals into a human-readable DEFCON status.
    
    Responsibilities:
    1. Read Coherence, Pattern, and Threshold artifacts.
    2. Apply Hierarchical Logic (Red > Orange > Yellow > Green).
    3. Publish Band Artifact and Ledger Transition.
    """
    
    AGMS_ROOT = "runtime/agms"
    
    @staticmethod
    def compute_band() -> Dict[str, Any]:
        """
        Main entry point.
        """
        assert NO_EXECUTION_GUARD is True, "AGMS MUST NOT EXECUTE"
        
        root = get_artifacts_root()
        now = datetime.now(timezone.utc)
        
        # 1. READ INPUTS
        # We rely on previous days' artifacts
        coh_res = safe_read_or_fallback("runtime/agms/agms_coherence_snapshot.json")
        pat_res = safe_read_or_fallback("runtime/agms/agms_patterns.json")
        try:
             # Day 24 artifact
             thresh_res = safe_read_or_fallback("runtime/agms/agms_dynamic_thresholds.json")
        except:
             thresh_res = {"success": False} # Handle missing D24 during bootstrap
             
        # Extract meaningful values or safe defaults
        coherence = coh_res.get("data", {}).get("score", 100) if coh_res["success"] else 100
        drift_count = pat_res.get("data", {}).get("total_drift_events", 0) if pat_res["success"] else 0
        multiplier = 1.0
        if thresh_res["success"]:
            multiplier = thresh_res["data"].get("multiplier", 1.0)
            
        # 2. DETERMINE BAND (Hierarchical)
        band = "GREEN"
        level = 0
        reasons = []
        
        # Start checking from most critical
        
        # RED Checks
        if coherence <= 70:
            band = "RED"
            level = 3
            reasons.append(f"Critical Coherence ({coherence})")
            
        # ORANGE Checks (If not already RED)
        if level < 2:
            if coherence <= 80:
                band = "ORANGE"
                level = 2
                reasons.append(f"Low Coherence ({coherence})")
            elif drift_count >= 5:
                band = "ORANGE"
                level = 2
                reasons.append(f"High Drift ({drift_count})")
            elif multiplier < 0.9:
                band = "ORANGE"
                level = 2
                reasons.append(f"Tightened Thresholds ({multiplier}x)")
                
        # YELLOW Checks (If not already HIGHER)
        if level < 1:
            if drift_count >= 2:
                band = "YELLOW"
                level = 1
                reasons.append(f"Minor Drift ({drift_count})")
            if multiplier < 1.0: # e.g. 0.9
                band = "YELLOW" 
                level = 1
                reasons.append("Thresholds Non-Standard")
                
        if level == 0:
            reasons.append("Nominal Metrics")
            
        result = {
            "timestamp_utc": now.isoformat(),
            "band": band,
            "level": level,
            "reasons": reasons,
            "metrics": {
                "coherence": coherence,
                "drift_count": drift_count,
                "multiplier": multiplier
            }
        }
        
        # 3. PERSIST
        AGMSStabilityBands._persist_artifacts(root, result, now)
        
        return result

    @staticmethod
    def _persist_artifacts(root: Path, result: Dict[str, Any], now: datetime):
        agms_dir = root / AGMSStabilityBands.AGMS_ROOT
        
        # 1. Band Snapshot
        atomic_write_json(str(agms_dir / "agms_stability_band.json"), result)
        
        # 2. Ledger (Append Only)
        # We might want to deduplicate consecutive identical bands to save space, 
        # but for now explicit logging is safer for audit.
        entry = {
            "timestamp_utc": result["timestamp_utc"],
            "band": result["band"],
            "level": result["level"],
            "reasons": result["reasons"]
        }
        append_to_ledger("runtime/agms/agms_band_ledger.jsonl", entry)
