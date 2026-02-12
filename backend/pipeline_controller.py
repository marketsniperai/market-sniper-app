import os
import json
import time
import sys
import uuid
import logging
from pathlib import Path
from datetime import datetime, timezone
from backend.artifacts.io import atomic_write_json, safe_read_or_fallback
# Lazy imports to avoid circular deps or heavy loads if just checking lock
# import backend.pipeline_full as pipeline_full
# import backend.pipeline_light as pipeline_light

# Setup Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Constants
OUTPUTS_ROOT = Path(os.environ.get("OUTPUTS_PATH", "backend/outputs"))
FULL_DIR = OUTPUTS_ROOT / "full"
LIGHT_DIR = OUTPUTS_ROOT / "light"
LOCK_FILE = OUTPUTS_ROOT / "os_lock.json"
LEDGER_FILE = OUTPUTS_ROOT / "autopilot_ledger.json"

COOLDOWN_FULL_SECONDS = 3600  # 1 hour
COOLDOWN_LIGHT_SECONDS = 300  # 5 minutes

class PipelineLock:
    def __init__(self, run_id: str, mode: str):
        self.run_id = run_id
        self.mode = mode
        self.locked = False

    def acquire(self):
        if LOCK_FILE.exists():
            # Check staleness? For now, fail fast.
            # In a real system, we might check if file is > 2h old (zombie lock)
            logger.warning(f"Lock file exists: {LOCK_FILE}")
            return False
            
        lock_data = {
            "locked": True,
            "mode": self.mode,
            "started_at_utc": datetime.utcnow().isoformat(),
            "run_id": self.run_id,
            "owner": "cloud_run_job"
        }
        
        try:
            # We use "x" mode for exclusive creation. 
            # Note: GCSFuse might have race conditions, but this is best effort for OS level.
            with open(LOCK_FILE, "x") as f:
                json.dump(lock_data, f, indent=2)
            self.locked = True
            logger.info(f"Lock acquired for {self.mode} run {self.run_id}")
            return True
        except FileExistsError:
            logger.warning("Lock acquisition failed (race condition).")
            return False
        except Exception as e:
            logger.error(f"Lock acquisition error: {e}")
            return False

    def release(self):
        if self.locked:
            try:
                if LOCK_FILE.exists():
                    os.remove(LOCK_FILE)
                    logger.info("Lock released.")
                self.locked = False
            except Exception as e:
                logger.error(f"Failed to release lock: {e}")

def check_cooldown(mode: str) -> bool:
    """Returns True if allowed to run, False if in cooldown."""
    if not LEDGER_FILE.exists():
        return True

    try:
        data = safe_read_or_fallback(LEDGER_FILE.name)["data"] # Using utils which assumes relative to root if not absolute? 
        # safe_read_or_fallback uses default ARTIFACTS_ROOT which might not be set correctly here if we rely on it.
        # Let's read directly for safety in controller to be explicit.
        with open(LEDGER_FILE, "r") as f:
             data = json.load(f)
             
        key = "last_full_run_utc" if mode == "FULL" else "last_light_run_utc"
        last_ts = data.get(key)
        
        if not last_ts:
            return True
            
        last_dt = datetime.fromisoformat(last_ts)
        # Normalize naive
        if last_dt.tzinfo is not None:
             last_dt = last_dt.replace(tzinfo=None)
             
        now = datetime.utcnow()
        age = (now - last_dt).total_seconds()
        
        limit = COOLDOWN_FULL_SECONDS if mode == "FULL" else COOLDOWN_LIGHT_SECONDS
        
        if age < limit:
            logger.warning(f"COOLDOWN_SKIP: Mode {mode} run {age:.1f}s ago. Limit {limit}s.")
            return False
            
        return True
    except Exception as e:
        logger.warning(f"Ledger read failed: {e}. Assuming safe to run.")
        return True

def update_ledger(mode: str, run_id: str):
    try:
        data = {}
        if LEDGER_FILE.exists():
             with open(LEDGER_FILE, "r") as f:
                 data = json.load(f)
        
        now_ts = datetime.utcnow().isoformat()
        if mode == "FULL":
            data["last_full_run_utc"] = now_ts
        else:
            data["last_light_run_utc"] = now_ts
            
        data["full_cooldown_seconds"] = COOLDOWN_FULL_SECONDS
        data["light_cooldown_seconds"] = COOLDOWN_LIGHT_SECONDS
        data["notes"] = "cooldown enforcement"
        
        atomic_write_json(LEDGER_FILE.name, data) # atomic_write_json writes to ARTIFACTS_ROOT by default. 
        # We need to be careful. atomic_write_json imports ARTIFACTS_ROOT from backend.artifacts.io.
        # Let's inspect backend.artifacts.io later. For now, manual atomic write here or assume io uses same OUTPUTS_PATH env var.
        
        # Re-implementing quick atomic write here to avoid dep confusion for now
        tmp_file = LEDGER_FILE.with_suffix(".tmp")
        with open(tmp_file, "w") as f:
            json.dump(data, f, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp_file, LEDGER_FILE)
        
        logger.info(f"Ledger updated for {mode}.")
    except Exception as e:
        logger.error(f"Failed to update ledger: {e}")

def trigger_pipeline(mode: str = "AUTO"):
    """
    Main entrypoint.
    mode: FULL | LIGHT | AUTO (defaults to FULL for now)
    """
    # 0. Resolve Mode
    if mode == "AUTO":
        mode = "FULL" # Default for Day 10
        
    run_id = str(uuid.uuid4())
    logger.info(f"Triggering Pipeline: Mode={mode} RunID={run_id}")
    
    # 1. Output Setup
    target_dir = FULL_DIR if mode == "FULL" else LIGHT_DIR
    target_dir.mkdir(parents=True, exist_ok=True)
    
    # 2. Lock
    file_lock = PipelineLock(run_id, mode)
    if not file_lock.acquire():
        logger.warning("LOCK_SKIP: Returning cleanly.")
        return {"result": "SKIPPED", "reason": "LOCKED"}
        
    try:
        # 3. Cooldown
        if not check_cooldown(mode):
            return {"result": "SKIPPED", "reason": "COOLDOWN"}
            
        # 4. Execution
        generated = []
        if mode == "FULL":
            from backend.pipeline_full import run_full_pipeline
            generated = run_full_pipeline(run_id, output_dir=target_dir)
        elif mode == "LIGHT":
            import backend.pipeline_light as pipeline_light
            generated = pipeline_light.run_light_pipeline(run_id, output_dir=target_dir)
        else:
            raise ValueError(f"Unknown mode: {mode}")
            
        # 5. Ledger Update
        update_ledger(mode, run_id)
        
        logger.info(f"Pipeline SUCCESS. Generated: {generated}")
        # 6. V4.1 System State Snapshot (Legacy + Full)
        # Added via Output Alignment Fix (D62.XX)
        try:
            from backend.os_ops.state_snapshot_engine import StateSnapshotEngine
            logger.info("Generating System State Snapshot...")
            snapshot = StateSnapshotEngine.generate_snapshot()
            generated.append("os/state_snapshot.json")
            generated.append("full/system_state.json")
        except Exception as e:
            logger.error(f"System State Generation Failed: {e}")
            # Non-blocking, but logged
            
        return {"result": "SUCCESS", "mode": mode, "run_id": run_id, "artifacts": generated}
        
    except Exception as e:
        logger.error(f"Pipeline FAILED: {e}", exc_info=True)
        return {"result": "FAILED", "error": str(e)}
    finally:
        file_lock.release()

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", default="FULL", help="FULL or LIGHT")
    args = parser.parse_args()
    
    result = trigger_pipeline(mode=args.mode)
    print(json.dumps(result))
    
    if result["result"] == "FAILED":
        sys.exit(1)
    # SKIPPED is Exit 0 (Success but no action)
    sys.exit(0)
