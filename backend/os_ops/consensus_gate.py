import json
import os
from pathlib import Path
from typing import Dict, Any
from backend.artifacts.io import get_artifacts_root, safe_read_or_fallback

class ConsensusGate:
    """
    Day 30.2: 2-Vote Consensus Enforcer.
    Ensures both Policy and Risk engines have voted ALLOW before Surgeon execution.
    """
    
    POLICY_VOTE_PATH = "runtime/autopilot/votes/policy_vote.json"
    RISK_VOTE_PATH = "runtime/shadow_repair/votes/risk_vote.json"
    
    @staticmethod
    def check_consensus(proposal_id: str) -> Dict[str, Any]:
        """
        Validates that both votes exist, match the proposal, and are ALLOW.
        """
        root = get_artifacts_root()
        p_vote_path = root / ConsensusGate.POLICY_VOTE_PATH
        r_vote_path = root / ConsensusGate.RISK_VOTE_PATH
        
        # 1. Read Votes
        p_res = safe_read_or_fallback(ConsensusGate.POLICY_VOTE_PATH)
        r_res = safe_read_or_fallback(ConsensusGate.RISK_VOTE_PATH)
        
        result = {
            "approved": False,
            "reasons": [],
            "votes": {
                "policy": "MISSING",
                "risk": "MISSING"
            }
        }
        
        # 2. Policy Vote Check
        if not p_res["success"]:
            result["reasons"].append("Policy Vote Missing")
        else:
            p_data = p_res["data"]
            result["votes"]["policy"] = p_data.get("decision", "UNKNOWN")
            
            if p_data.get("proposal_id") != proposal_id:
                result["reasons"].append(f"Policy Vote ID Mismatch ({p_data.get('proposal_id')} != {proposal_id})")
            elif p_data.get("decision") != "ALLOW":
                result["reasons"].append(f"Policy Vote DENY: {p_data.get('reasons')}")
                
        # 3. Risk Vote Check
        if not r_res["success"]:
            result["reasons"].append("Risk Vote Missing")
        else:
            r_data = r_res["data"]
            result["votes"]["risk"] = r_data.get("decision", "UNKNOWN")
            
            if r_data.get("proposal_id") != proposal_id:
                result["reasons"].append(f"Risk Vote ID Mismatch ({r_data.get('proposal_id')} != {proposal_id})")
            elif r_data.get("decision") != "ALLOW":
                result["reasons"].append(f"Risk Vote DENY: {r_data.get('reasons')}")

        # 4. Consensus
        if not result["reasons"]:
            result["approved"] = True
            
        return result
