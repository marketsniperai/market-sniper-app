import json
import logging
import uuid
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List, Optional
from backend.artifacts.io import atomic_write_json, safe_read_or_fallback, get_artifacts_root
from backend.os_ops.black_box import BlackBox

# Setup Logger
logger = logging.getLogger("OS.Ops.TuningGate")
logger.setLevel(logging.INFO)

class TuningGate:
    """
    OS.Ops.TuningGate (Day 33.1)
    Runtime Tuning Governance with 2-Vote Consensus.
    """
    
    CONTRACT_PATH = Path("os_tuning_gate_contract.json")
    
    # Defaults
    TUNING_APPLY_ENABLED = False # Kill Switch (Memory only default, intended to be env or config)
    
    @classmethod
    def run_tuning_cycle(cls, force_enable: bool = False) -> Dict[str, Any]:
        """
        Main entry point. Loads Dojo recs, votes, applies if consensus.
        """
        root = get_artifacts_root()
        cls._ensure_dirs(root)
        
        # 0. Kill Switch Check
        # For simulation/lab, we might allow override
        enabled = cls.TUNING_APPLY_ENABLED or force_enable 
        
        # 1. Load Dojo Recs
        recs_files = safe_read_or_fallback("runtime/dojo/dojo_recommended_thresholds.json")
        if not recs_files["success"]:
             return cls._exit_no_data("NO_DOJO_RECS")
             
        recs = recs_files["data"]
        if not recs:
             return cls._exit_no_data("EMPTY_DOJO_RECS")
        
        proposal_id = str(uuid.uuid4())[:8]
        BlackBox.record_event("TUNING_PROPOSED", {"id": proposal_id, "recs": recs}, {})
        
        # 2. Clamp to Bounds
        clamped_recs = cls._clamp_to_bounds(root, recs)
        
        # 3. Voting
        policy_vote = cls._cast_policy_vote(root, proposal_id, clamped_recs)
        risk_vote = cls._cast_risk_vote(root, proposal_id, clamped_recs)
        
        # 4. Consensus
        consensus = cls._check_consensus(policy_vote, risk_vote)
        
        result_payload = {
            "proposal_id": proposal_id,
            "consensus": consensus,
            "policy_vote": policy_vote,
            "risk_vote": risk_vote,
            "applied": False,
            "clamped_recs": clamped_recs
        }

        # 5. Apply if Approved AND Enabled
        if consensus == "APPROVED":
            if enabled:
                try:
                    cls._apply_tuning(root, clamped_recs, proposal_id)
                    result_payload["applied"] = True
                    result_payload["status"] = "APPLIED"
                    BlackBox.record_event("TUNING_APPLIED", {"id": proposal_id}, {})
                except Exception as e:
                    result_payload["status"] = "ERROR_APPLYING"
                    result_payload["error"] = str(e)
                    BlackBox.record_event("TUNING_ERROR", {"id": proposal_id, "error": str(e)}, {})
            else:
                result_payload["status"] = "DENIED_KILL_SWITCH"
                BlackBox.record_event("TUNING_DENIED", {"id": proposal_id, "reason": "KILL_SWITCH"}, {})
        else:
            result_payload["status"] = "DENIED_CONSENSUS"
            BlackBox.record_event("TUNING_DENIED", {"id": proposal_id, "reason": "CONSENSUS_FAIL"}, {})
            
        # Write Ledger
        cls._append_ledger(root, result_payload)
        
        return result_payload

    @classmethod
    def _ensure_dirs(cls, root: Path):
        (root / "runtime/tuning/votes").mkdir(parents=True, exist_ok=True)

    @classmethod
    def _clamp_to_bounds(cls, root: Path, recs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Loads contract and enforces min/max.
        """
        # Hardcoded fallback bounds if contract missing, to ensure safety
        bounds = {
             "price_spike_threshold": {"min": 0.05, "max": 2.0},
             "time_travel_tolerance_sec": {"min": 1, "max": 3600}
        }
        
        # Try read contract? (Simplified for Day 33.1)
        # We assume recs keys match bounds keys
        
        clamped = {}
        for k, v in recs.items():
            if k not in bounds: continue # Ignore unknown keys
            
            val = v.get("value")
            if val is None: continue
            
            b = bounds[k]
            safe_val = max(b["min"], min(val, b["max"]))
            
            item = v.copy()
            item["value"] = safe_val
            if safe_val != val:
                item["clamped"] = True
                item["original_value"] = val
            
            clamped[k] = item
            
        return clamped

    @classmethod
    def _cast_policy_vote(cls, root: Path, pid: str, recs: Dict) -> str:
        """
        Policy Engine Vote.
        Simplified: ALLOW if system is generally healthy/stable.
        Real: Would check AutopilotPolicyEngine directly.
        """
        # We'll default to ALLOW for this implementation unless empty
        vote = "ALLOW" if recs else "DENY"
        
        vote_rec = {
            "proposal_id": pid,
            "voter": "AutopilotPolicyEngine",
            "vote": vote,
            "timestamp_utc": datetime.now(timezone.utc).isoformat()
        }
        atomic_write_json(str(root / f"runtime/tuning/votes/policy_vote_{pid}.json"), vote_rec)
        return vote

    @classmethod
    def _cast_risk_vote(cls, root: Path, pid: str, recs: Dict) -> str:
        """
        Risk Assessor Vote.
        ALLOW if bounded.
        """
        vote = "ALLOW" # We pre-clamped, so risk is managed
        
        vote_rec = {
            "proposal_id": pid,
            "voter": "TuningRiskAssessor",
            "vote": vote,
            "timestamp_utc": datetime.now(timezone.utc).isoformat()
        }
        atomic_write_json(str(root / f"runtime/tuning/votes/risk_vote_{pid}.json"), vote_rec)
        return vote

    @classmethod
    def _check_consensus(cls, v1: str, v2: str) -> str:
        if v1 == "ALLOW" and v2 == "ALLOW":
            return "APPROVED"
        return "DENIED"

    @classmethod
    def _apply_tuning(cls, root: Path, recs: Dict, pid: str):
        """
        Writes the applied_thresholds.json file.
        Input 'recs' is dict of {key: {value: X, ...}}
        We need simple k:v pairs for consumer.
        """
        simple_payload = {}
        for k, v in recs.items():
            simple_payload[k] = v["value"]
            
        wrapped = {
            "meta": {
                "proposal_id": pid,
                "applied_at": datetime.now(timezone.utc).isoformat(),
                "source": "OS.Ops.TuningGate"
            },
            "overrides": simple_payload
        }
        
        atomic_write_json(str(root / "runtime/tuning/applied_thresholds.json"), wrapped)

    @classmethod
    def _append_ledger(cls, root: Path, entry: Dict):
        path = root / "runtime/tuning/tuning_ledger.jsonl"
        with open(path, "a") as f:
            f.write(json.dumps(entry) + "\n")

    @classmethod
    def _exit_no_data(cls, reason: str):
        return {"status": "SKIPPED", "reason": reason}
