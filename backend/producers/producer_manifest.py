from datetime import datetime, timezone
from backend.schemas.manifest_schema import RunManifest
import json
from pathlib import Path

# Centralized Manifest Logic
def generate_manifest(run_id: str, mode: str, window: str, status: str, capabilities: dict, data_status: dict) -> RunManifest:
    ts = datetime.now(timezone.utc).isoformat()
    
    # Calculate simple freshness (stub for Day 04, would be real delta)
    freshness = {k: 0.0 for k in data_status.keys()}
    
    manifest = RunManifest(
        run_id=run_id,
        build_id="DAY_04_REAL",
        timestamp=ts,
        status=status,
        mode=mode,
        window=window,
        capabilities=capabilities,
        data_status=data_status,
        freshness=freshness,
        schema_version="1.1"
    )
    return manifest
