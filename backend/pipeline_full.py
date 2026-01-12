import json
from datetime import datetime, timezone
from pathlib import Path
from backend.cadence_engine import get_window, get_now_et
from backend.producers.producer_manifest import generate_manifest
from backend.producers.producer_context import produce_context
from backend.producers.producer_dashboard import produce_dashboard

ARTIFACTS_ROOT = Path("backend/outputs")

def run_full_pipeline(run_id: str) -> list:
    """
    Generates FULL artifacts (Real v0):
    - run_manifest.json (v1.1)
    - context_market_sniper.json (Real v0)
    - dashboard_market_sniper.json (Real v0)
    """
    generated = []
    
    # 0. Context (Window)
    now_et = get_now_et()
    window_data = get_window(now_et)
    window_name = window_data["name"]
    
    # 1. Produce Context (Data Ingestion Happens Here)
    context_data = produce_context(run_id, window_name)
    with open(ARTIFACTS_ROOT / "context_market_sniper.json", "w") as f:
        json.dump(context_data, f, indent=2)
    generated.append("context_market_sniper.json")
    
    # 2. Produce Dashboard (Consumes Context/Snapshot)
    dashboard_data = produce_dashboard(run_id, context_data)
    with open(ARTIFACTS_ROOT / "dashboard_market_sniper.json", "w") as f:
        json.dump(dashboard_data, f, indent=2)
    generated.append("dashboard_market_sniper.json")
    
    # 3. Produce Manifest (Centralized)
    # Day 04: Capabilities/Status are inferred or hardcoded for v0
    manifest = generate_manifest(
        run_id=run_id,
        mode="FULL",
        window=window_name,
        status="LIVE",
        capabilities={"ingestion": "STUB_MODE" if "STUB" in dashboard_data["message"] else "LIVE"},
        data_status={"prices": "OK", "options": "MISSING"}
    )
    
    with open(ARTIFACTS_ROOT / "run_manifest.json", "w") as f:
        f.write(manifest.json(indent=2)) # Pydantic v1 style (or model_dump_json in v2)
    generated.append("run_manifest.json")
    
    return generated
