import json
from pathlib import Path
from datetime import datetime, timezone
from backend.cadence_engine import get_window, get_now_et
from backend.producers.producer_manifest import generate_manifest
from backend.os_ops.immune_system import ImmuneSystemEngine

def run_light_pipeline(run_id: str, output_dir: Path) -> list:
    """
    Generates LIGHT artifacts (Pulse):
    - run_manifest.json (v1.1)
    - pulse_report.json (Light Truth)
    """
    from backend.os_ops.black_box import BlackBox
    BlackBox.record_event("PIPELINE_RUN", {"run_id": run_id, "mode": "LIGHT", "status": "START"}, {"output_dir": str(output_dir)})

    generated = []
    
    # 0. Context
    now_et = get_now_et()
    window_data = get_window(now_et)
    window_name = window_data["name"]
    
    # 1. Produce Pulse Report (Stub for now)
    # In future, this fetches fast live data (e.g. price check)
    pulse_data = {
        "run_id": run_id,
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "pulse_status": "ALIVE",
        "notes": "Light Pipeline Execution"
    }
    
    with open(output_dir / "pulse_report.json", "w") as f:
        json.dump(pulse_data, f, indent=2)
    generated.append("pulse_report.json")

    # 1.5. Immune System Scan (Shadow Sanitize)
    try:
        immune_result = ImmuneSystemEngine.run(
            payload=pulse_data,
            context={"run_id": run_id, "pipeline": "LIGHT", "stage": "pulse_produced"}
        )
    except Exception as e:
        print(f"Immune System Error: {e}")
        immune_result = {"status": "ERROR", "flags": [], "mode": "FAILSAFE"}
    
    # 2. Produce Manifest
    manifest = generate_manifest(
        run_id=run_id,
        mode="LIGHT",
        window=window_name,
        status="LIVE",
        capabilities={"ingestion": "STUB_LIGHT"},
        data_status={"prices": "OK"}
    )
    
    with open(output_dir / "run_manifest.json", "w") as f:
        # Robust Serialization (V1/V2 Compatible)
        try:
            # V2 prefer model_dump
            data = manifest.model_dump() if hasattr(manifest, "model_dump") else manifest.dict()
            # Inject Immune Flags
            if "immune_result" in locals():
                data["immune_flags"] = immune_result.get("flags", [])
                data["immune_status"] = immune_result.get("status", "UNKNOWN")
            
            f.write(json.dumps(data, indent=2, default=str))
        except Exception as e:
            # Emergency fallback (should not happen if model is valid)
            print(f"Serialization Failed: {e}")
            f.write(manifest.json(indent=2) if hasattr(manifest, "json") else str(manifest))
    generated.append("run_manifest.json")
    
    # Black Box End
    BlackBox.record_event("PIPELINE_RUN", {"run_id": run_id, "mode": "LIGHT", "status": "COMPLETE", "generated": generated}, {})
    
    return generated
