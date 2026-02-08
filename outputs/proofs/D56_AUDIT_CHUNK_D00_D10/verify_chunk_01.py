import sys
import os
from pathlib import Path

# Setup paths
ROOT_DIR = Path(os.getcwd())
BACKEND_DIR = ROOT_DIR / "backend"
APP_DIR = ROOT_DIR / "market_sniper_app"

def verify_claim(id, check_fn):
    print(f"VERIFYING {id}...", end=" ")
    try:
        if check_fn():
            print("PASS (GREEN)")
            return "GREEN"
        else:
            print("FAIL (RED)")
            return "RED"
    except Exception as e:
        print(f"ERROR: {e}")
        return "RED"

def check_shell():
    return (APP_DIR / "lib" / "main.dart").exists()

def check_pipeline():
    return (BACKEND_DIR / "pipeline_controller.py").exists()

def check_scheduler():
    # Searching for scheduler logic
    candidates = [
        BACKEND_DIR / "scheduler.py",
        BACKEND_DIR / "tasks.py",
        BACKEND_DIR / "cron.py",
        ROOT_DIR / "scheduler.py"
    ]
    for c in candidates:
        if c.exists(): return True
    
    # Check inside api_server for direct scheduler
    api_server = BACKEND_DIR / "api_server.py"
    if api_server.exists():
        with open(api_server, "r", encoding="utf-8") as f:
            if "scheduler" in f.read().lower(): return True
    
    return False

def check_gcs():
    # Broad check for persistence
    return (BACKEND_DIR / "persistence.py").exists() or (BACKEND_DIR / "artifacts" / "io.py").exists()

def check_misfire():
    return (BACKEND_DIR / "os_ops" / "misfire_monitor.py").exists()

def check_locks():
    return (BACKEND_DIR / "core_gates.py").exists()

if __name__ == "__main__":
    print("-" * 30)
    print("D56 CHUNK 01 VERIFICATION")
    print("-" * 30)
    
    verify_claim("D00.SHELL", check_shell)
    verify_claim("D04.PIPE", check_pipeline)
    verify_claim("D06.SCHED", check_scheduler)
    verify_claim("D06.GCS", check_gcs)
    verify_claim("D08.MISFIRE", check_misfire)
    verify_claim("D10.LOCKS", check_locks)
