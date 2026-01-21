import json
import logging
from pathlib import Path
from typing import Optional, List, Dict
from pydantic import BaseModel

from backend.os_ops.elite_context_safety_validator import EliteContextSafetyValidator
from backend.artifacts.io import get_artifacts_root

logger = logging.getLogger("EliteAGMSRecallReader")

class AGMSRecallSnapshot(BaseModel):
    status: str # SUCCESS, UNAVAILABLE, SAFETY_BLOCKED
    patterns: List[str]
    safety_filtered: bool = False

class EliteAGMSRecallReader:
    # We look for a runtime artifact that aggregates patterns.
    # Since D43.05 is the Reader, and the Producer might not exist yet, 
    # we define where it SHOULD be.
    ARTIFACT_PATH = get_artifacts_root() / "runtime/agms/agms_recall.json"
    CONTRACT_PATH = Path("c:/MSR/MarketSniperRepo/outputs/os/os_elite_agms_recall_contract.json")

    def __init__(self):
        self.validator = EliteContextSafetyValidator()
        self.contract = self._load_contract()

    def _load_contract(self) -> Dict:
        try:
            if self.CONTRACT_PATH.exists():
                with open(self.CONTRACT_PATH, "r") as f:
                    return json.load(f)
        except:
            pass
        return {}

    def get_recall(self, tier: str = "elite") -> AGMSRecallSnapshot:
        """
        Reads AGMS Recall data.
        Applies Tier constraints.
        Applies Safety validation.
        """
        if not self.ARTIFACT_PATH.exists():
            return AGMSRecallSnapshot(status="UNAVAILABLE", patterns=[])

        try:
            with open(self.ARTIFACT_PATH, "r") as f:
                data = json.load(f)
            
            raw_patterns = data.get("patterns", [])
            if not isinstance(raw_patterns, list):
                raw_patterns = []

            # Filter by Tier
            # Free: 1 pattern
            # Plus/Elite: 3 patterns (max per contract)
            limit = 1 if tier.lower() == "free" else 3
            
            # Additional Contract constraint: max_patterns check
            contract_max = self.contract.get("max_patterns", 3)
            limit = min(limit, contract_max)
            
            selected_patterns = raw_patterns[:limit]
            
            if not selected_patterns:
                return AGMSRecallSnapshot(status="UNAVAILABLE", patterns=[])

            # Safety Validation
            safe_patterns, was_filtered = self.validator.validate_bullets(selected_patterns)
            
            # Additional Contract Validation (Forbidden claims)
            forbidden_claims = self.contract.get("forbidden_claims", [])
            final_patterns = []
            for p in safe_patterns:
                p_lower = p.lower()
                clean = True
                for claim in forbidden_claims:
                    if claim in p_lower:
                        clean = False
                        was_filtered = True # Flag generic safety
                        break
                if clean:
                    final_patterns.append(p)
                else:
                    # Replace with fallback generic or skip?
                    # Validator usually replaces with fallback message. 
                    # If we found an explicit forbidden claim (contract level), let's skip it or use generic.
                    final_patterns.append("Pattern redacted (Policy limit).")

            return AGMSRecallSnapshot(
                status="SUCCESS",
                patterns=final_patterns,
                safety_filtered=was_filtered
            )

        except Exception as e:
            logger.error(f"Error reading AGMS Recall: {e}")
            return AGMSRecallSnapshot(status="UNAVAILABLE", patterns=[])
