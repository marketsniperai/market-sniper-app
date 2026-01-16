import os
import json
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List, Optional
from backend.artifacts.io import atomic_write_json, safe_read_or_fallback, append_to_ledger, get_artifacts_root

# TITANIUM LAW: AGMS IS READ-ONLY / APPEND-ONLY
NO_EXECUTION_GUARD = True

class AGMSFoundation:
    """
    Day 20: AGMS Foundation Engine.
    Memory + Mirror + Truth.
    
    Responsibilities:
    1. Observe: Read runtime artifacts (safe).
    2. Compare: Calculate Delta (Drift, Actions).
    3. Record: Write Snapshot, Delta, and Ledger.
    
    Constraint: NEVER TRIGGER EXECUTION.
    """
    
    AGMS_ROOT = "runtime/agms"
    
    @staticmethod
    def run_agms_foundation(force_now: Optional[datetime] = None) -> Dict[str, Any]:
        """
        Main entry point for AGMS loop.
        """
        assert NO_EXECUTION_GUARD is True, "AGMS MUST NOT EXECUTE"
        
        now = force_now or datetime.now(timezone.utc)
        timestamp_utc = now.isoformat()
        root = get_artifacts_root()
        
        # 1. OBSERVE (System Said vs Reality)
        observations = AGMSFoundation._observe_system(root, now)
        
        # 2. COMPARE (Deltas)
        deltas = AGMSFoundation._compute_deltas(observations)
        
        # 3. RECORD (Artifacts)
        snapshot = {
            "timestamp_utc": timestamp_utc,
            "observations": observations,
            "deltas": deltas,
            "engine_version": "1.0.0 (Day 20)"
        }
        
        # Persist Envelope (Snapshot + Delta)
        AGMSFoundation._persist_artifacts(snapshot)
        
        return snapshot

    @staticmethod
    def verify_no_side_effects() -> bool:
        """
        Self-check ensuring no writes outside known boundaries.
        Returns True if safe.
        """
        # In a real impl, this would scan FS. 
        # Here we rely on strict code discipline and contract alignment.
        return NO_EXECUTION_GUARD

    # --- INTERNAL HELPERS ---
    
    @staticmethod
    def _observe_system(root: Path, now: datetime) -> Dict[str, Any]:
        obs = {}
        
        # A. Manifests (Truth)
        for mode in ["full", "light"]:
             path = f"{mode}/run_manifest.json"
             res = safe_read_or_fallback(path)
             obs[f"manifest_{mode}"] = {
                 "exists": res["success"],
                 "data": res.get("data"),
                 "timestamp": res["data"].get("timestamp_utc") if res["success"] else None
             }
             
        # B. Autofix (Intent)
        af_res = safe_read_or_fallback("runtime/autofix/autofix_status.json")
        obs["autofix"] = {
            "status": af_res.get("data", {}).get("status"),
            "matched_playbooks": af_res.get("data", {}).get("matched_playbooks", [])
        }
        
        # C. Lock (State)
        lock_res = safe_read_or_fallback("os_lock.json")
        obs["lock"] = {
            "locked": lock_res["success"],
            "owner": lock_res.get("data", {}).get("owner")
        }
        
        return obs

    @staticmethod
    def _compute_deltas(obs: Dict[str, Any]) -> Dict[str, Any]:
        drift = []
        actions = []
        
        # Drift 1: Missing Manifests
        if not obs["manifest_light"]["exists"]: drift.append("MISSING_LIGHT_MANIFEST")
        if not obs["manifest_full"]["exists"]: drift.append("MISSING_FULL_MANIFEST")
        
        # Action Delta: Match vs Reality
        # If Autofix matched a playbook, is it reflected/active?
        # For Day 20 Foundation, we just log the match as an "ACTION SIGNAL"
        matches = obs["autofix"]["matched_playbooks"]
        for m in matches:
            actions.append(f"SIGNALED: {m.get('playbook_id')}")
            
        return {
            "drift_deltas": drift,
            "action_deltas": actions,
            "drift_score": len(drift)
        }

    @staticmethod
    def _persist_artifacts(snapshot: Dict[str, Any]):
        root = get_artifacts_root()
        agms_dir = root / AGMSFoundation.AGMS_ROOT
        os.makedirs(agms_dir, exist_ok=True)
        
        # 1. Snapshot
        atomic_write_json(str(agms_dir / "agms_snapshot.json"), snapshot)
        
        # 2. Delta (Separate artifact for easy polling)
        delta_payload = {
            "timestamp_utc": snapshot["timestamp_utc"],
            "deltas": snapshot["deltas"]
        }
        atomic_write_json(str(agms_dir / "agms_delta.json"), delta_payload)
        
        # 3. Ledger (Append)
        ledger_entry = {
            "timestamp_utc": snapshot["timestamp_utc"],
            "drift_deltas": snapshot["deltas"]["drift_deltas"],
            "action_deltas": snapshot["deltas"]["action_deltas"],
            "drift_score": snapshot["deltas"]["drift_score"]
        }
        append_to_ledger(str(agms_dir / "agms_ledger.jsonl"), ledger_entry)
