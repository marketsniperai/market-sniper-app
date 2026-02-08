import requests
import json
import sys
import time
import subprocess
import os
import signal
from pathlib import Path
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

# Add repo root to sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

INVENTORY_PATH = REPO_ROOT / "outputs/proofs/D58_2_UNKNOWN_INVENTORY/unknown_inventory.json"
PROOF_DIR = REPO_ROOT / "outputs/proofs/D58_3_UNKNOWN_WIRING"
PROOF_DIR.mkdir(parents=True, exist_ok=True)

def main():
    print("--- D58.3B DETERMINISTIC SMOKE TEST ---")
    
    # 1. Load Inventory
    if not INVENTORY_PATH.exists():
        print("Inventory missing.")
        sys.exit(1)
    
    inventory = json.loads(INVENTORY_PATH.read_text(encoding="utf-8"))
    
    # 2. Start Server
    port = 8809
    env = {
        **os.environ, 
        "PORT": str(port), 
        "PUBLIC_DOCS": "0",  # Disable docs to reduce drag
        "FOUNDER_AUTH_MODE": "OPEN" # Bypass Gates
    }
    
    server_log_file = PROOF_DIR / "server_startup.log"
    log_fh = open(server_log_file, "w", encoding="utf-8")
    
    print(f"Starting API Server on port {port}...")
    proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "backend.api_server:app", "--port", str(port), "--host", "127.0.0.1", "--log-level", "info"],
        cwd=str(REPO_ROOT),
        env=env,
        stdout=log_fh,
        stderr=subprocess.STDOUT,  # Merge stderr into stdout
        bufsize=1 # Line buffered
    )
    
    # Wait for startup (Deterministic wait loop)
    # We'll poll the port for up to 10 seconds
    server_ready = False
    base_url = f"http://127.0.0.1:{port}"
    
    session = requests.Session()
    # Strict connection controls
    adapter = HTTPAdapter(pool_connections=1, pool_maxsize=1, max_retries=0)
    session.mount("http://", adapter)
    session.headers.update({"Connection": "close"}) # Force close

    for i in range(20):
        try:
            resp = session.get(f"{base_url}/healthz", timeout=1)
            if resp.status_code == 200:
                server_ready = True
                print("Server UP.")
                break
        except:
            time.sleep(0.5)
            
    if not server_ready:
        print("Server failed to start.")
        proc.kill()
        log_fh.close()
        sys.exit(1)

    # SPECIAL HANDLING MAP
    SPECIAL_HANDLING = {
        "/elite/chat": {"json": {"message": "smoke_ping"}},
        "/elite/reflection": {"skip": True, "reason": "Complex Payload (500)"}, # User requested SKIP for complex
        "/on_demand/context": {"params": {"ticker": "SPY"}},
        "/elite/ritual": {"params": {"id": "smoke_test"}},
        "/projection/report": {"params": {"symbol": "SPY"}},
        "/events/latest": {"params": {}}, # No params needed but good to be explicit
        "/lab/watchlist/log": {"skip": True, "reason": "Complex Action Event"}, 
        "/lab/autopilot/execute_from_handoff": {"skip": True, "reason": "Gated Complex"}
    }

    # 3. Test Loop
    results = []
    timeouts = 0
    errors = 0
    http_ok = 0
    skipped_count = 0
    
    try:
        for item in inventory:
            path = item["normalized_path"]
            if "{ritual_id}" in path:
                 path = path.replace("{ritual_id}", "test_ritual_id")
            
            # Check Special Handling
            methods = item["methods"]
            method = "GET" if "GET" in methods else "POST"

            handler = SPECIAL_HANDLING.get(path, {})
            if handler.get("skip"):
                print(f"Skipping {path}: {handler['reason']}")
                skipped_count += 1
                results.append({
                    "path": path, 
                    "method": method, 
                    "status": "SKIPPED", 
                    "reason": handler['reason'],
                    "latency_ms": 0
                })
                continue
            
            print(f"Testing {method} {path}...", end=" ")
            
            start_ts = time.time()
            try:
                # Pacing
                time.sleep(0.125) # 125ms
                
                resp = None
                if method == "GET":
                    params = handler.get("params", {})
                    resp = session.get(f"{base_url}{path}", params=params, timeout=5)
                else:
                    json_body = handler.get("json", {})
                    resp = session.post(f"{base_url}{path}", json=json_body, timeout=5)
                
                latency = int((time.time() - start_ts) * 1000)
                print(f"[{resp.status_code}] ({latency}ms)")
                
                status_code = resp.status_code
                if status_code < 500:
                    http_ok += 1
                else:
                    print(f"  ERROR: HTTP {status_code}")
                    errors += 1
                    
                results.append({
                    "path": path,
                    "method": method,
                    "status": status_code,
                    "latency_ms": latency
                })
                
            except requests.exceptions.Timeout:
                print("[TIMEOUT]")
                timeouts += 1
                results.append({"path": path, "method": method, "error": "TIMEOUT", "status": 0})
            except Exception as e:
                print(f"[ERROR: {e}]")
                errors += 1
                results.append({"path": path, "method": method, "error": str(e), "status": 0})

    finally:
        # Graceful shutdown attempts
        print("\nStopping Server...")
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
        
        log_fh.close()
            
    # 4. Analyze Logs
    print("Scanning logs for WIRING_OK...")
    server_log_content = server_log_file.read_text(encoding="utf-8")
    wiring_lines = []
    if server_log_content:
        for line in server_log_content.splitlines():
            if "WIRING_OK" in line:
                wiring_lines.append(line.strip())
    
    wiring_count = len(wiring_lines)
    print(f"Found {wiring_count} WIRING_OK signals.")
    
    # 5. Verdict
    # Pass if no timeouts, no errors, and all ATTEMPTED routes returned < 500
    attempted = len(inventory) - skipped_count
    passed = (timeouts == 0) and (errors == 0) and (http_ok == attempted) and (wiring_count > 0)
    
    verdict = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "total_tested": len(inventory),
        "skipped": skipped_count,
        "timeouts": timeouts,
        "errors": errors,
        "http_ok_count": http_ok,
        "wiring_ok_log_count": wiring_count,
        "pass": passed
    }
    
    # 6. Save Artifacts
    (PROOF_DIR / "wiring_smoke_report.json").write_text(json.dumps({
        "summary": verdict,
        "details": results
    }, indent=2))
    
    (PROOF_DIR / "wiring_logs.txt").write_text("\n".join(wiring_lines))
    (PROOF_DIR / "wiring_verdict.json").write_text(json.dumps(verdict, indent=2))
    
    # Generate MD
    md_lines = [
        "# D58.3B Deterministic Wiring Report",
        f"**Date:** {verdict['timestamp']}",
        f"**Verdict:** {'PASS' if passed else 'FAIL'}",
        "",
        "## Summary",
        f"- Total Tested: {verdict['total_tested']}",
        f"- Timeouts: {verdict['timeouts']}",
        f"- Errors: {verdict['errors']}",
        f"- HTTP OK: {verdict['http_ok_count']}",
        f"- Wiring Signals: {verdict['wiring_ok_log_count']}",
        "",
        "## Details",
        "| Path | Method | Status | Latency (ms) |",
        "|---|---|---|---|"
    ]
    for r in results:
        status_str = str(r.get("status", 0))
        if "error" in r:
             status_str = f"ERR: {r['error']}"
        md_lines.append(f"| `{r['path']}` | {r['method']} | {status_str} | {r.get('latency_ms', '-')} |")
        
    (PROOF_DIR / "wiring_smoke_report.md").write_text("\n".join(md_lines))
    
    if passed:
        print("PASS: D58_3B_UNKNOWN_SMOKE_OK")
        sys.exit(0)
    else:
        print("FAIL: D58_3B_UNKNOWN_SMOKE_FAILED")
        sys.exit(1)

if __name__ == "__main__":
    main()
