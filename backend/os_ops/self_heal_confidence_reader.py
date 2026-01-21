import json
from pathlib import Path
from typing import Optional, Literal, List
from datetime import datetime
from pydantic import BaseModel

# Configuration
ROOT_DIR = Path("c:/MSR/MarketSniperRepo").resolve()
OUTPUTS_DIR = ROOT_DIR / "outputs"
OS_DIR = OUTPUTS_DIR / "os"
CONFIDENCE_ARTIFACT_PATH = OS_DIR / "os_self_heal_confidence.json"

class ConfidenceEntry(BaseModel):
    engine: str
    action_code: str
    confidence: Literal["HIGH", "MED", "LOW"]
    evidence: List[str]
    notes: Optional[str]

class SelfHealConfidenceSnapshot(BaseModel):
    timestamp_utc: datetime
    run_id: str
    overall: Literal["HIGH", "MED", "LOW"]
    entries: List[ConfidenceEntry]

class SelfHealConfidenceReader:
    @staticmethod
    def get_snapshot() -> Optional[SelfHealConfidenceSnapshot]:
        """
        Reads the self-heal confidence artifact.
        Returns None if missing or invalid.
        """
        if not CONFIDENCE_ARTIFACT_PATH.exists():
            return None
            
        try:
            with open(CONFIDENCE_ARTIFACT_PATH, "r") as f:
                data = json.load(f)
            
            # Pydantic validation
            snapshot = SelfHealConfidenceSnapshot(**data)
            return snapshot
        except Exception:
            # Graceful degradation on any read/parse error
            return None
