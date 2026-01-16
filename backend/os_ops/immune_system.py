import json
import math
import os
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List

# Setup Logger
logger = logging.getLogger("OS.ImmuneSystem")
logger.setLevel(logging.INFO)

class ImmuneSystemEngine:
    """
    OS.ImmuneSystem (Day 32)
    Active defense against poisoned inputs.
    
    Modes:
    - SHADOW_SANITIZE: Detect, Label, Report. Do NOT Block.
    - ENFORCE: Detect, Block, Quarantine. (Future)
    """
    
    CONTRACT_PATH = Path("os_immune_system_contract.json")
    OUTPUT_DIR = Path("backend/outputs/runtime/immune")
    
    @classmethod
    def load_contract(cls) -> Dict[str, Any]:
        if not cls.CONTRACT_PATH.exists():
            # Fallback default if contract missing (should verify first)
            return {"mode": "SHADOW_SANITIZE", "thresholds": {}}
        try:
            with open(cls.CONTRACT_PATH, "r") as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load contract: {e}")
            return {"mode": "SHADOW_SANITIZE", "thresholds": {}}

    @classmethod
    def run(cls, payload: Dict[str, Any], context: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Main entry point. 
        Analyzes payload, detects anomalies, updates artifacts.
        Returns a summary dict with 'flags' (list of signals) and 'status'.
        """
        # 1. Init
        cls.OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        contract = cls.load_contract()
        mode = contract.get("mode", "SHADOW_SANITIZE")
        thresholds = contract.get("thresholds", {})
        
        run_id = context.get("run_id", "unknown") if context else "unknown"
        timestamp = datetime.now(timezone.utc).isoformat()
        
        flags = []
        
        # 2. Analysis
        
        # 2.1 NULL_PACKET
        if not payload:
            flags.append("NULL_PACKET")
        
        # 2.2 REQUIRED_KEYS_MISSING (Simple heuristic for context/pulse)
        # We don't know exact schema for every payload, but checks common ones if keys exist
        # If payload looks like a Context/Snapshot
        if isinstance(payload, dict):
            # General sanity check for NaNs/Negatives in obvious fields
            cls._check_numeric_sanity(payload, flags)
            
            # 2.3 TIME_TRAVEL
            # Check 'timestamp_utc' or similar
            cls._check_time_sanity(payload, flags, thresholds.get("future_time_tolerance_seconds", 300))
        
        # 3. Decision
        status = "CLEAN" if not flags else "FLAGGED"
        
        # 4. Artifacts
        result = {
            "run_id": run_id,
            "timestamp": timestamp,
            "mode": mode,
            "status": status,
            "flags": flags,
            "scan_meta": {
                "payload_keys": list(payload.keys()) if isinstance(payload, dict) else [],
                "context_meta": context
            }
        }
        
        cls._write_artifacts(result, contract)
        
        # Day 34: Black Box Hook
        if flags:
             from backend.os_ops.black_box import BlackBox
             BlackBox.record_event("IMMUNE_FLAG", result, {})
        
        if mode == "SHADOW_SANITIZE":
            # NEVER BLOCK
            if flags:
                logger.warning(f"ImmuneSystem SHADOW Alert: {flags} in run {run_id}")
            return result
        elif mode == "ENFORCE":
            # FUTURE: Raise exception or return blocking signal
            if flags:
                logger.error(f"ImmuneSystem ENFORCE Block: {flags} in run {run_id}")
            return result
            
        return result

    @classmethod
    def _check_numeric_sanity(cls, payload: Dict[str, Any], flags: List[str]):
        """Recursively check for NaNs, Infs, or invalid Negatives in likely places."""
        # This is a shallow scan or specialized deep scan?
        # V1: Shallow scan of top-level or known nested dicts
        
        def is_bad_number(val):
            if isinstance(val, (int, float)):
                if math.isnan(val) or math.isinf(val):
                    return True
            return False

        # Scan
        # We iterate values. If dict, simplistic recursive 1-level or full?
        # Let's do a simple full traversal helper for V1 limited depth
        stack = [payload]
        depth_limit = 100 # safety
        items_checked = 0
        
        while stack and items_checked < 1000:
            current = stack.pop()
            items_checked += 1
            
            if isinstance(current, dict):
                for k, v in current.items():
                    if is_bad_number(v):
                        if "NEGATIVE_OR_NAN" not in flags: flags.append("NEGATIVE_OR_NAN")
                    elif isinstance(v, (dict, list)):
                        stack.append(v)
            elif isinstance(current, list):
                for item in current:
                    if is_bad_number(item):
                        if "NEGATIVE_OR_NAN" not in flags: flags.append("NEGATIVE_OR_NAN")
                    elif isinstance(item, (dict, list)):
                        stack.append(item)
                        
    @classmethod
    def _check_time_sanity(cls, payload: Dict[str, Any], flags: List[str], tolerance: int):
        # Look for "timestamp" or "timestamp_utc"
        ts_str = payload.get("timestamp_utc") or payload.get("timestamp")
        if not ts_str:
            return
            
        try:
            # Parse
            ts = datetime.fromisoformat(str(ts_str).replace("Z", "+00:00"))
            now = datetime.now(timezone.utc)
            diff = (ts - now).total_seconds()
            
            if diff > tolerance:
                if "TIME_TRAVEL" not in flags: flags.append("TIME_TRAVEL")
        except:
            # logic to handle parse errors silently or flag format?
            # For now ignore parser errors to avoid noise
            pass

    @classmethod
    def _write_artifacts(cls, result: Dict[str, Any], contract: Dict[str, Any]):
        try:
            # 1. Report (latest only)
            report_path = cls.OUTPUT_DIR / "immune_report.json"
            with open(report_path, "w") as f:
                json.dump(result, f, indent=2)
                
            # 2. Snapshot (Status Summary)
            snapshot_path = cls.OUTPUT_DIR / "immune_snapshot.json"
            snapshot = {
                "latest_run_id": result["run_id"],
                "latest_status": result["status"],
                "mode": result["mode"],
                "last_update_utc": result["timestamp"],
                "active_signals_count": len(result["flags"])
            }
            with open(snapshot_path, "w") as f:
                json.dump(snapshot, f, indent=2)
                
            # 3. Ledger (Append Only)
            ledger_path = cls.OUTPUT_DIR / "immune_ledger.jsonl"
            with open(ledger_path, "a") as f:
                f.write(json.dumps(result) + "\n")
                
        except Exception as e:
            logger.error(f"Failed to write immune artifacts: {e}")
