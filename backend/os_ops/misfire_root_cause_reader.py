import json
from pathlib import Path
from typing import Optional, Literal
from datetime import datetime
from pydantic import BaseModel, Field

# Configuration
ROOT_DIR = Path("c:/MSR/MarketSniperRepo").resolve()
OUTPUTS_DIR = ROOT_DIR / "outputs"
OS_DIR = OUTPUTS_DIR / "os"
MISFIRE_ROOT_CAUSE_PATH = OS_DIR / "os_misfire_root_cause.json"

class MisfireRootCauseSnapshot(BaseModel):
    timestamp_utc: datetime
    incident_id: str
    misfire_type: str
    originating_module: str
    detected_by: str
    primary_artifact: Optional[str]
    pipeline_mode: Optional[str]
    fallback_used: Optional[str]
    action_taken: Optional[str]
    outcome: str
    notes: Optional[str]

class MisfireRootCauseReader:
    @staticmethod
    def get_snapshot() -> Optional[MisfireRootCauseSnapshot]:
        """
        Reads the misfire root cause artifact.
        Returns None if missing or invalid.
        """
        if not MISFIRE_ROOT_CAUSE_PATH.exists():
            return None
            
        try:
            with open(MISFIRE_ROOT_CAUSE_PATH, "r") as f:
                data = json.load(f)
            
            # Pydantic validation
            snapshot = MisfireRootCauseSnapshot(**data)
            return snapshot
        except Exception:
            # Graceful degradation on any read/parse error
            return None
