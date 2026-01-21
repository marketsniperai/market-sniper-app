import json
from pathlib import Path
from typing import Optional, List, Any
from datetime import datetime
from pydantic import BaseModel

# Configuration
ROOT_DIR = Path("c:/MSR/MarketSniperRepo").resolve()
OUTPUTS_DIR = ROOT_DIR / "outputs"
OS_DIR = OUTPUTS_DIR / "os"
RED_BUTTON_ARTIFACT_PATH = OS_DIR / "os_red_button_status.json"

class RedButtonRunSummary(BaseModel):
    run_id: str
    action: str
    timestamp_utc: datetime
    status: str
    notes: Optional[str]

class RedButtonStatusSnapshot(BaseModel):
    timestamp_utc: datetime
    available: bool
    founder_required: bool
    capabilities: List[str]
    last_run: Optional[RedButtonRunSummary]

class RedButtonReader:
    @staticmethod
    def get_snapshot() -> Optional[RedButtonStatusSnapshot]:
        """
        Reads the Red Button status artifact.
        Returns None if missing or invalid.
        """
        if not RED_BUTTON_ARTIFACT_PATH.exists():
            return None
            
        try:
            with open(RED_BUTTON_ARTIFACT_PATH, "r") as f:
                data = json.load(f)
            
            # Pydantic validation
            snapshot = RedButtonStatusSnapshot(**data)
            return snapshot
        except Exception:
            # Graceful degradation on any read/parse error
            return None
