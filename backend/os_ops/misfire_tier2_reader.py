import json
from pathlib import Path
from typing import Optional, List, Literal
from datetime import datetime
from pydantic import BaseModel

# Configuration
ROOT_DIR = Path("c:/MSR/MarketSniperRepo").resolve()
OUTPUTS_DIR = ROOT_DIR / "outputs"
OS_DIR = OUTPUTS_DIR / "os"
MISFIRE_TIER2_ARTIFACT_PATH = OS_DIR / "os_misfire_auto_recovery_tier2.json"

class MisfireEscalationStep(BaseModel):
    step_id: str
    description: str
    attempted: bool
    permitted: bool
    gate_reason: Optional[str]
    result: Optional[str]
    timestamp_utc: Optional[datetime]

class MisfireTier2Snapshot(BaseModel):
    timestamp_utc: datetime
    incident_id: str
    detected_by: str
    escalation_policy: str
    steps: List[MisfireEscalationStep]
    final_outcome: str
    action_taken: Optional[str]
    notes: Optional[str]

class MisfireTier2Reader:
    @staticmethod
    def get_snapshot() -> Optional[MisfireTier2Snapshot]:
        """
        Reads the Misfire Tier 2 artifact.
        Returns None if missing or invalid.
        """
        if not MISFIRE_TIER2_ARTIFACT_PATH.exists():
            return None
            
        try:
            with open(MISFIRE_TIER2_ARTIFACT_PATH, "r") as f:
                data = json.load(f)
            
            # Pydantic validation
            snapshot = MisfireTier2Snapshot(**data)
            return snapshot
        except Exception:
            # Graceful degradation on any read/parse error
            return None
