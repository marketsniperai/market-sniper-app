import json
import os
from datetime import datetime, timezone
from pathlib import Path

ARTIFACTS_ROOT = Path("backend/outputs")
PULSE_DIR = ARTIFACTS_ROOT / "pulse"

def run_light_pipeline(run_id: str) -> list:
    """
    Generates LIGHT artifacts:
    - manifest (update)
    - pulse_report.json
    """
    ts = datetime.now(timezone.utc).isoformat()
    generated = []
    
    # 1. Manifest Update
    manifest = {
        "run_id": run_id,
        "build_id": "DAY_03_LIGHT",
        "timestamp": ts,
        "status": "LIVE_PULSE",
        "pipeline_type": "LIGHT",
        "schema_version": "1.0"
    }
    with open(ARTIFACTS_ROOT / "run_manifest.json", "w") as f:
        json.dump(manifest, f, indent=2)
    generated.append("run_manifest.json")
    
    # 2. Pulse Report
    os.makedirs(PULSE_DIR, exist_ok=True)
    pulse = {
        "run_id": run_id,
        "timestamp": ts,
        "heartbeat": "OK",
        "active_modules": ["time", "cadence", "controller"]
    }
    with open(PULSE_DIR / "pulse_report.json", "w") as f:
        json.dump(pulse, f, indent=2)
    generated.append("pulse/pulse_report.json")
    
    return generated
