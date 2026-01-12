import json
import os
import uuid
from datetime import datetime, timezone, timedelta
from pathlib import Path

from backend.os_time import get_now_et
from backend.cadence_engine import get_window, resolve_run_mode

import backend.pipeline_full as pipeline_full
import backend.pipeline_light as pipeline_light

# Artifacts Root
OUTPUTS_DIR = Path("backend/outputs")
RUNTIME_DIR = OUTPUTS_DIR / "runtime"
LOG_FILE = RUNTIME_DIR / "pipeline_run_log.jsonl"
LOCK_FILE = RUNTIME_DIR / "pipeline_lock.json"
PUBLISH_MARKER = OUTPUTS_DIR / "publish_complete.json"

class LockManager:
    def __init__(self, run_id: str, mode: str, window: str):
        self.run_id = run_id
        self.mode = mode
        self.window = window
        self.lock_path = LOCK_FILE
        self.timeout_sec = 600 # 10 minutes

    def acquire(self) -> bool:
        now_utc = datetime.now(timezone.utc)
        
        if self.lock_path.exists():
            try:
                with open(self.lock_path, "r") as f:
                    data = json.load(f)
                
                expires_at = datetime.fromisoformat(data["expires_at_utc"])
                if now_utc < expires_at:
                    return False # Locked and active
            except (json.JSONDecodeError, KeyError, ValueError):
                # Corrupt lock file, overwrite it
                pass
        
        # Create Lock
        lock_data = {
            "locked": True,
            "run_id": self.run_id,
            "mode": self.mode,
            "window": self.window,
            "acquired_at_utc": now_utc.isoformat(),
            "expires_at_utc": (now_utc + timedelta(seconds=self.timeout_sec)).isoformat()
        }
        with open(self.lock_path, "w") as f:
            json.dump(lock_data, f, indent=2)
            
        return True

    def release(self):
        if self.lock_path.exists():
            try:
                os.remove(self.lock_path)
            except:
                pass

def write_publish_marker(run_id: str, mode: str, window: str, artifacts: list, success: bool):
    marker = {
        "run_id": run_id,
        "mode": mode,
        "window": window,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "artifacts_written": artifacts,
        "ok": success
    }
    with open(PUBLISH_MARKER, "w") as f:
        json.dump(marker, f, indent=2)

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
    # Strict Fix: Resolve AUTO based on cadence
    now_et = get_now_et()
    window_data = get_window(now_et)
    window_name = window_data["name"]
    
    if mode == "AUTO":
        if window_name == "PREMARKET":
            final_mode = "FULL"
        else:
            final_mode = "LIGHT"
    else:
        final_mode = mode
    
    # 2. Lock Check
    locker = LockManager(run_id, final_mode, window_name)
    if not locker.acquire():
        return {
            "ok": False,
            "status": "SKIP",
            "reason": "LOCK_ACTIVE",
            "run_id": run_id
        }
    
    # 3. Execution
    artifacts_generated = []
    success = False
    error = None
    
    try:
        if final_mode == "FULL":
            artifacts = pipeline_full.run_full_pipeline(run_id)
            artifacts_generated.extend(artifacts)
        else:
            artifacts = pipeline_light.run_light_pipeline(run_id)
            artifacts_generated.extend(artifacts)
            
        success = True
    except Exception as e:
        error = str(e)
    finally:
        locker.release()
        
    # 4. Publish Marker & Log
    write_publish_marker(run_id, final_mode, window_name, artifacts_generated, success)
    
    log_entry = {
        "run_id": run_id,
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "mode": final_mode,
        "window": window_name,
        "success": success,
        "error": error,
        "artifacts": artifacts_generated
    }
    
    with open(LOG_FILE, "a") as f:
        f.write(json.dumps(log_entry) + "\n")
        
    return {
        "ok": success,
        "mode": final_mode,
        "window": window_name,
        "run_id": run_id,
        "artifacts_written": artifacts_generated,
        "error": error
    }
