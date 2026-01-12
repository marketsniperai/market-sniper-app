import json
import os
import uuid
from datetime import datetime, timezone
from pathlib import Path

from backend.os_time import get_now_et
from backend.cadence_engine import get_window, resolve_run_mode

# Producers (Dynamic Imports to avoid circular deps if any)
# In Day 03 scaffolding, we import them directly
import backend.pipeline_full as pipeline_full
import backend.pipeline_light as pipeline_light

# Artifacts Root
OUTPUTS_DIR = Path("backend/outputs")
RUNTIME_DIR = OUTPUTS_DIR / "runtime"
LOG_FILE = RUNTIME_DIR / "pipeline_run_log.jsonl"
LOCK_FILE = RUNTIME_DIR / "pipeline_lock.json"

def trigger_pipeline(mode="AUTO", tier="AUTO", run_id=None):
    """
    Main entry point for Autonomy.
    Triggers FULL or LIGHT logic.
    """
    # 0. Setup
    if not run_id:
        run_id = str(uuid.uuid4())
    
    os.makedirs(RUNTIME_DIR, exist_ok=True)
    
    # 1. Resolve Logic
    final_mode = resolve_run_mode(mode)
    now_et = get_now_et()
    window = get_window(now_et)
    
    # 2. Lock Check (Stub - Force release for Day 03 dev)
    # real impl would check file existence and age
    
    # 3. Execution
    artifacts_generated = []
    
    try:
        if final_mode == "FULL":
            artifacts = pipeline_full.run_full_pipeline(run_id)
            artifacts_generated.extend(artifacts)
        else:
            artifacts = pipeline_light.run_light_pipeline(run_id)
            artifacts_generated.extend(artifacts)
            
        success = True
        error = None
    except Exception as e:
        success = False
        error = str(e)
        
    # 4. Log
    log_entry = {
        "run_id": run_id,
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "mode": final_mode,
        "window": window["name"],
        "success": success,
        "error": error,
        "artifacts": artifacts_generated
    }
    
    with open(LOG_FILE, "a") as f:
        f.write(json.dumps(log_entry) + "\n")
        
    return {
        "ok": success,
        "mode": final_mode,
        "window": window["name"],
        "run_id": run_id,
        "artifacts_written": artifacts_generated,
        "error": error
    }
