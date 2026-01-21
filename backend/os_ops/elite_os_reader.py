import json
from pathlib import Path
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, Field

# Constants for Canonical Paths
ARTIFACTS_ROOT = Path("backend/outputs")
PATH_RUN_MANIFEST_FULL = ARTIFACTS_ROOT / "full/run_manifest.json"
PATH_RUN_MANIFEST_LIGHT = ARTIFACTS_ROOT / "light/run_manifest.json"
PATH_GLOBAL_RISK = ARTIFACTS_ROOT / "os/global_risk_state.json"
PATH_OVERLAY_SNAPSHOT = ARTIFACTS_ROOT / "os/overlay_snapshot.json"

# --- Models ---

class RunManifestSnapshot(BaseModel):
    run_id: str = "UNKNOWN"
    mode: str = "UNKNOWN"
    timestamp: str = "UNKNOWN"
    status: str = "UNKNOWN"

class GlobalRiskSnapshot(BaseModel):
    risk_state: str = "UNKNOWN"
    confidence: float = 0.0
    drivers: List[str] = Field(default_factory=list)

class OverlaySnapshot(BaseModel):
    status: str = "UNKNOWN"
    active_overlays: List[str] = Field(default_factory=list)

class EliteOSSnapshot(BaseModel):
    run_manifest: Optional[RunManifestSnapshot] = None
    global_risk: Optional[GlobalRiskSnapshot] = None
    overlay: Optional[OverlaySnapshot] = None
    generated_at_utc: str = "UNKNOWN"

# --- Reader Logic ---

class EliteOSReader:
    """
    D43.03: Read-Only Elite OS Reader.
    Loads canonical OS artifacts for Elite explanations.
    Bounded, Safe, Degrade-First.
    """

    @staticmethod
    def get_snapshot() -> EliteOSSnapshot:
        """
        Orchestrates reading of all three pillars.
        Returns a consolidated snapshot.
        """
        manifest = EliteOSReader._read_run_manifest()
        risk = EliteOSReader._read_risk_state()
        overlay = EliteOSReader._read_overlay_state()
        
        from datetime import datetime, timezone
        now_utc = datetime.now(timezone.utc).isoformat()

        return EliteOSSnapshot(
            run_manifest=manifest,
            global_risk=risk,
            overlay=overlay,
            generated_at_utc=now_utc
        )

    @staticmethod
    def get_first_interaction_script() -> Optional[FirstInteractionScript]:
        """
        Reads the canonical first interaction script.
        """
        try:
            # Handle path resolution relative to repo root
            root_dir = Path(__file__).resolve().parent.parent.parent
            path = root_dir / EliteOSReader.PATH_FIRST_INTERACTION
            
            if not path.exists():
                return None
                
            with open(path, 'r') as f:
                data = json.load(f)
                return FirstInteractionScript(**data)
        except Exception:
            return None

    @staticmethod
    def _read_run_manifest() -> Optional[RunManifestSnapshot]:
        # Try FULL first, then LIGHT
        path = PATH_RUN_MANIFEST_FULL
        if not path.exists():
            path = PATH_RUN_MANIFEST_LIGHT
        
        if not path.exists():
            return None
            
        try:
            with open(path, "r") as f:
                data = json.load(f)
            # Safe mapping
            return RunManifestSnapshot(
                run_id=data.get("run_id", "UNKNOWN"),
                mode=data.get("mode", "UNKNOWN"),
                timestamp=data.get("timestamp", "UNKNOWN"),
                status=data.get("status", "UNKNOWN")
            )
        except Exception:
            return None

    @staticmethod
    def _read_risk_state() -> Optional[GlobalRiskSnapshot]:
        if not PATH_GLOBAL_RISK.exists():
            return None
            
        try:
            with open(PATH_GLOBAL_RISK, "r") as f:
                data = json.load(f)
            return GlobalRiskSnapshot(
                risk_state=data.get("risk_state", "UNKNOWN"),
                confidence=data.get("confidence", 0.0),
                drivers=data.get("drivers", [])
            )
        except Exception:
            return None

    @staticmethod
    def _read_overlay_state() -> Optional[OverlaySnapshot]:
        if not PATH_OVERLAY_SNAPSHOT.exists():
            return None
            
        try:
            with open(PATH_OVERLAY_SNAPSHOT, "r") as f:
                data = json.load(f)
            return OverlaySnapshot(
                status=data.get("status", "UNKNOWN"),
                active_overlays=data.get("active_overlays", [])
            )
        except Exception:
            return None
