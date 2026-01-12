import json
import os
from pathlib import Path
from backend.cadence_engine import get_window, get_now_et
from backend.producers.producer_manifest import generate_manifest
from backend.producers.producer_pulse import produce_pulse

ARTIFACTS_ROOT = Path("backend/outputs")
PULSE_DIR = ARTIFACTS_ROOT / "pulse"

def run_light_pipeline(run_id: str) -> list:
    """
    Generates LIGHT artifacts (Real v0):
    - run_manifest.json (Update only)
    - pulse/pulse_report.json (Real)
    """
    generated = []
    
    # 0. Context
    now_et = get_now_et()
    window_data = get_window(now_et)
    window_name = window_data["name"]
    
    # 1. Produce Pulse
    os.makedirs(PULSE_DIR, exist_ok=True)
    pulse_data = produce_pulse(run_id, "LIGHT", window_name)
    with open(PULSE_DIR / "pulse_report.json", "w") as f:
        json.dump(pulse_data, f, indent=2)
    generated.append("pulse/pulse_report.json")
    
    # 2. Produce Manifest (Update)
    manifest = generate_manifest(
        run_id=run_id,
        mode="LIGHT",
        window=window_name,
        status="LIVE_PULSE",
        capabilities={"ingestion": "SKIPPED"},
        data_status={"prices": "SKIPPED"}
    )
    with open(ARTIFACTS_ROOT / "run_manifest.json", "w") as f:
        f.write(manifest.json(indent=2))
    generated.append("run_manifest.json")
    
    return generated
