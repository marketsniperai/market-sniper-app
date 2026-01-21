import json
from pathlib import Path
from typing import Optional, Literal, List
from datetime import datetime
from pydantic import BaseModel

# Configuration
ROOT_DIR = Path("c:/MSR/MarketSniperRepo").resolve()
OUTPUTS_DIR = ROOT_DIR / "outputs"
OS_DIR = OUTPUTS_DIR / "os"
COOLDOWN_ARTIFACT_PATH = OS_DIR / "os_cooldown_transparency.json"

class CooldownEntry(BaseModel):
    engine: str
    action_code: str
    attempted: bool
    permitted: bool
    gate_reason: str
    cooldown_remaining_seconds: Optional[int]
    throttle_window_seconds: Optional[int]
    last_executed_timestamp_utc: Optional[datetime]
    notes: Optional[str]

class CooldownTransparencySnapshot(BaseModel):
    timestamp_utc: datetime
    run_id: Optional[str]
    entries: List[CooldownEntry]

class CooldownTransparencyReader:
    @staticmethod
    def get_snapshot() -> Optional[CooldownTransparencySnapshot]:
        """
        Reads the cooldown transparency artifact.
        Returns None if missing or invalid.
        """
        if not COOLDOWN_ARTIFACT_PATH.exists():
            return None
            
        try:
            with open(COOLDOWN_ARTIFACT_PATH, "r") as f:
                data = json.load(f)
            
            # Pydantic validation
            snapshot = CooldownTransparencySnapshot(**data)
            return snapshot
        except Exception:
            # Graceful degradation on any read/parse error
            return None
