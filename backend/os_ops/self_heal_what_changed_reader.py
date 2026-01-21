import json
from pathlib import Path
from typing import Optional, Literal, List
from datetime import datetime
from pydantic import BaseModel

# Configuration
ROOT_DIR = Path("c:/MSR/MarketSniperRepo").resolve()
OUTPUTS_DIR = ROOT_DIR / "outputs"
OS_DIR = OUTPUTS_DIR / "os"
WHAT_CHANGED_ARTIFACT_PATH = OS_DIR / "os_self_heal_what_changed.json"

class ArtifactUpdate(BaseModel):
    path: str
    change_type: Literal["CREATED", "UPDATED", "DELETED", "UNCHANGED"]
    before_hash: Optional[str]
    after_hash: Optional[str]

class StateTransition(BaseModel):
    from_state: Optional[str]
    to_state: Optional[str]
    unlocked: bool

class SelfHealWhatChangedSnapshot(BaseModel):
    timestamp_utc: datetime
    run_id: str
    summary: Optional[str]
    artifacts_updated: List[ArtifactUpdate]
    state_transition: Optional[StateTransition]

class SelfHealWhatChangedReader:
    @staticmethod
    def get_snapshot() -> Optional[SelfHealWhatChangedSnapshot]:
        """
        Reads the self-heal what changed artifact.
        Returns None if missing or invalid.
        """
        if not WHAT_CHANGED_ARTIFACT_PATH.exists():
            return None
            
        try:
            with open(WHAT_CHANGED_ARTIFACT_PATH, "r") as f:
                data = json.load(f)
            
            # Pydantic validation
            snapshot = SelfHealWhatChangedSnapshot(**data)
            return snapshot
        except Exception:
            # Graceful degradation on any read/parse error
            return None
