import json
from datetime import datetime, timezone
from pathlib import Path
from backend.cadence_engine import get_window, get_now_et
from backend.producers.producer_manifest import generate_manifest
from backend.producers.producer_context import produce_context
from backend.producers.producer_dashboard import produce_dashboard
import backend.misfire_monitor as misfire_monitor
from backend.os_ops.immune_system import ImmuneSystemEngine

ARTIFACTS_ROOT = Path("backend/outputs")

def run_full_pipeline(run_id: str, output_dir: Path = ARTIFACTS_ROOT) -> list:
    """
    Generates FULL artifacts (Real v0):
    - run_manifest.json (v1.1)
    - context_market_sniper.json (Real v0)
    - dashboard_market_sniper.json (Real v0)
    """
    from backend.os_ops.black_box import BlackBox
    BlackBox.record_event("PIPELINE_RUN", {"run_id": run_id, "mode": "FULL", "status": "START"}, {"output_dir": str(output_dir)})

    generated = []
    
    # 0. Context (Window)
    now_et = get_now_et()
    window_data = get_window(now_et)
    window_name = window_data["name"]
    
    # 1. Produce Context (Data Ingestion Happens Here)
    context_data = produce_context(run_id, window_name)
    with open(output_dir / "context_market_sniper.json", "w") as f:
        json.dump(context_data, f, indent=2)
    generated.append("context_market_sniper.json")

    # 1.5. Immune System Scan (Shadow Sanitize)
    try:
        immune_result = ImmuneSystemEngine.run(
            payload=context_data,
            context={"run_id": run_id, "pipeline": "FULL", "stage": "context_produced"}
        )
    except Exception as e:
        print(f"Immune System Error: {e}")
        immune_result = {"status": "ERROR", "flags": [], "mode": "FAILSAFE"}
    
    # 2. Produce Dashboard (Consumes Context/Snapshot)
    dashboard_data = produce_dashboard(run_id, context_data)
    with open(output_dir / "dashboard_market_sniper.json", "w") as f:
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
    
    with open(output_dir / "run_manifest.json", "w") as f:
        # Robust Serialization (V1/V2 Compatible)
        try:
            data = manifest.model_dump() if hasattr(manifest, "model_dump") else manifest.dict()
            # Inject Immune Flags (Non-breaking append)
            if "immune_result" in locals():
                data["immune_flags"] = immune_result.get("flags", [])
                data["immune_status"] = immune_result.get("status", "UNKNOWN")
                data["immune_mode"] = immune_result.get("mode", "UNKNOWN")
            
            f.write(json.dumps(data, indent=2, default=str))
        except Exception:
            f.write(manifest.json(indent=2))
    generated.append("run_manifest.json")
    
    # 4. Update Misfire Monitor (Nominal)
    # Note: Misfire monitor might need to know WHERE to look, but it reads from "system truth".
    # For now, we just update the report. 
    # TODO: MisfireMonitor should probably write to the same output_dir or the global one? 
    # Contract says misfire_report is System Truth. It should likely live in the mode dir AND maybe global?
    # Controller handles "truth", but misfire monitor reads from ARTIFACTS_ROOT.
    # Let's write misfire report to output_dir too.
    try:
        # We manually update misfire report in the output dir for consistency
        report = {
            "status": "NOMINAL",
            "artifact_age_seconds": 0.0,
            "reason": "OK",
            "last_run_id": run_id,
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "recommended_action": "NONE"
        }
        with open(output_dir / "misfire_report.json", "w") as f:
            json.dump(report, f, indent=2)
        generated.append("misfire_report.json")
        
        # Also try global update for legacy compatibility if needed? 
        # No, Day 10 moves to Namespaces. API must read from namespaces.
    except Exception as e:
        print(f"Warning: Failed to update misfire report: {e}")
        
    BlackBox.record_event("PIPELINE_RUN", {"run_id": run_id, "mode": "FULL", "status": "COMPLETE", "generated": generated}, {})
    
    return generated
