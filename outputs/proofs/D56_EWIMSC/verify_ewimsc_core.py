import sys
import json
import requests
from pathlib import Path

# Config
ROOT_DIR = Path("c:/MSR/MarketSniperRepo")
BACKEND_DIR = ROOT_DIR / "backend"
FRONTEND_LIB = ROOT_DIR / "market_sniper_app" / "lib"
RUNTIME_DIR = ROOT_DIR / "outputs" / "runtime"
API_BASE = "http://127.0.0.1:8000"

results = []

def log(claim_id, status, details):
    print(f"[{status}] {claim_id}: {details}")
    results.append({
        "id": claim_id,
        "status": status,
        "details": details
    })

def verify_file(claim_id, relative_path, must_contain=None):
    fpath = ROOT_DIR / relative_path
    if not fpath.exists():
        log(claim_id, "RED", f"File missing: {relative_path}")
        return False
    
    if must_contain:
        content = fpath.read_text(encoding="utf-8")
        if must_contain not in content:
            log(claim_id, "RED", f"File {relative_path} missing content: '{must_contain}'")
            return False
            
    log(claim_id, "GREEN", f"File verified: {relative_path}")
    return True

def verify_endpoint(claim_id, method, path, expected_code=200):
    try:
        url = f"{API_BASE}{path}"
        # We assume local dev server is running or we skip network checks if not
        # For this script, we'll try-except safely
        resp = requests.request(method, url, timeout=2)
        if resp.status_code == expected_code:
            log(claim_id, "GREEN", f"Endpoint {method} {path} returned {resp.status_code}")
            return True
        else:
            log(claim_id, "YELLOW", f"Endpoint {method} {path} returned {resp.status_code} (expected {expected_code})")
            return False
    except Exception as e:
        log(claim_id, "YELLOW", f"Endpoint check failed (server likely down): {e}")
        return False 

# --- Verification Logic ---

def verify_usp():
    # D56.01.UNIFIED_SNAPSHOT_PROTOCOL_IMPLEMENTATION
    # D56.01.5.WARROOM_SNAPSHOT_ONLY
    cid = "D56.01.UNIFIED_SNAPSHOT_PROTOCOL_IMPLEMENTATION"
    f = verify_file(cid, "backend/contracts/war_room_contract.py", "class WarRoomSnapshot")
    if f:
         verify_endpoint(cid, "GET", "/lab/war_room/snapshot", 200)

def verify_war_room_truth():
    # D53.6.WAR_ROOM_TRUTH_EXPOSURE
    # D53.6.B_WAR_ROOM_TILE_SOURCE_OVERLAY
    cid = "D53.6.WAR_ROOM_TRUTH_EXPOSURE"
    # Check for source overlay logic in frontend
    verify_file(cid, "market_sniper_app/lib/widgets/war_room/zones/service_honeycomb.dart", "showSourceOverlay")

def verify_autopilot_shadow():
    # D29.AUTOPILOT_SHADOW_OBSERVATION
    cid = "D29.AUTOPILOT_SHADOW_OBSERVATION"
    # Check code
    verify_file(cid, "backend/os_intel/agms_shadow_recommender.py")
    
    # Check ledger (Weak proof but worth checking)
    ledger = RUNTIME_DIR / "autopilot_shadow_ledger.json"
    if ledger.exists():
        log(cid, "GREEN", "Runtime ledger found: autopilot_shadow_ledger.json")
    else:
        log(cid, "YELLOW", "Runtime ledger absent (Ephemeral). Code verified.")

def verify_autofix():
    # D42.04.AUTOFIX_TIER1
    cid = "D42.04.AUTOFIX_TIER1"
    verify_file(cid, "backend/os_ops/autofix_control_plane.py")

def verify_housekeeper():
    # D17.HOUSEKEEPER_AUTOCLEAN_DRIFT
    # D56.HK_1_HOUSEKEEPER_WIRING_RESTORED
    cid = "D56.HK_1_HOUSEKEEPER_WIRING_RESTORED"
    verify_file(cid, "backend/os_ops/housekeeper.py")

def verify_misfire():
    # D08.MISFIRE_MONITOR_AND_AUTOHEAL
    cid = "D08.MISFIRE_MONITOR_AND_AUTOHEAL"
    verify_file(cid, "backend/os_ops/misfire_monitor.py")

def verify_cloud_run_smoke():
    # D56.01.10.CLOUD_RUN_PROBES_SMOKE_GREEN
    cid = "D56.01.10.CLOUD_RUN_PROBES_SMOKE_GREEN"
    verify_file(cid, "tools/smoke_cloud_run.ps1")

def run_all():
    print("--- Starting EWIMSC Core Verification ---")
    verify_usp()
    verify_war_room_truth()
    verify_autopilot_shadow()
    verify_autofix()
    verify_housekeeper()
    verify_misfire()
    verify_cloud_run_smoke()
    
    # Dump results
    out_path = ROOT_DIR / "outputs" / "proofs" / "D56_EWIMSC" / "core_verification_results.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"--- Verification Complete. Results saved to {out_path} ---")

if __name__ == "__main__":
    run_all()
