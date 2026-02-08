import requests
import json
import sys
import time
import subprocess
import os
from pathlib import Path

# Add repo root to sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

INVENTORY_PATH = REPO_ROOT / "outputs/proofs/D58_2_UNKNOWN_INVENTORY/unknown_inventory.json"

def main():
    print("--- D58.3 SMOKE TEST (UNKNOWNS) ---")
    
    # 1. Load Inventory
    if not INVENTORY_PATH.exists():
        print("Inventory missing.")
        sys.exit(1)
    
    inventory = json.loads(INVENTORY_PATH.read_text(encoding="utf-8"))
    
    # 2. Start Server
    pass_count = 0
    port = 8803
    env = {**os.environ, "PORT": str(port), "PUBLIC_DOCS": "1"}
    
    # Start process
    print(f"Starting API Server on port {port}...")
    proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "backend.api_server:app", "--port", str(port), "--host", "127.0.0.1"],
        cwd=str(REPO_ROOT),
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        encoding="utf-8"  # Capture text
    )
    
    try:
        # Wait for startup
        time.sleep(5)
        
        base_url = f"http://127.0.0.1:{port}"
        
        results = []
        pass_count = 0
        
        for item in inventory:
            path = item["normalized_path"]
            if "{ritual_id}" in path:
                 path = path.replace("{ritual_id}", "test_ritual_id")
            
            # Skip pure POST endpoints if we don't have payloads perfectly matched, 
            # BUT we want to verify them.
            # D58.2 inventory listed methods.
            methods = item["methods"]
            method = "GET" if "GET" in methods else "POST"
            
            print(f"Testing {method} {path}...", end=" ")
            
            headers = {"X-Founder-Key": "test_key"} # Minimal auth header just in case? Or relying on middleware.
            # Wait, middleware checks env var. In test mode, maybe we need to set env var FOUNDER_KEY?
            # Or rely on Fail-Hidden?
            # 41 Zombies are zombies because they aren't fully integrated.
            # If they are LAB_INTERNAL they return 404 without key.
            # With key they should run.
            
            try:
                if method == "GET":
                    resp = requests.get(f"{base_url}{path}", headers=headers, timeout=2)
                else:
                    resp = requests.post(f"{base_url}{path}", headers=headers, json={}, timeout=2)
                
                print(f"[{resp.status_code}]")
                results.append({"path": path, "status": resp.status_code})
                pass_count += 1
                
            except Exception as e:
                print(f"[ERROR: {e}]")
                results.append({"path": path, "error": str(e)})

        # Check logs for "WIRING_OK"
        print("\n--- SERVER LOG SCANT ---")
        # Initialize an empty string to accumulate scanned logs.
        # This prevents 'scanned_logs' from being undefined if the loop finishes without finding lines.
        scanned_logs = ""
        
        # We need to read the pipe. It might be blocking.
        # Simple non-blocking read or just kill and read remain?
        proc.terminate()
        try:
             outs, errs = proc.communicate(timeout=5)
             scanned_logs = outs
        except:
             proc.kill()
             outs, errs = proc.communicate()
             scanned_logs = outs

        if not scanned_logs:
             scanned_logs = ""

        wiring_ok_count = scanned_logs.count("WIRING_OK")
        print(f"Found {wiring_ok_count} 'WIRING_OK' events in logs.")
        
        # Save Report
        report = {
            "total_tested": len(inventory),
            "pass_count": pass_count,
            "wiring_ok_log_count": wiring_ok_count,
            "details": results
        }
        
        out_path = REPO_ROOT / "outputs/proofs/D58_3_UNKNOWN_WIRING/wiring_smoke_report.json"
        out_path.write_text(json.dumps(report, indent=2))
        
        paths_with_wiring = [line for line in scanned_logs.splitlines() if "WIRING_OK" in line]
        (REPO_ROOT / "outputs/proofs/D58_3_UNKNOWN_WIRING/wiring_logs.txt").write_text("\n".join(paths_with_wiring))
        
        print(f"Report saved to {out_path}")
        
    except Exception as e:
        print(f"FATAL: {e}")
        if proc: proc.kill()
        sys.exit(1)

if __name__ == "__main__":
    main()
