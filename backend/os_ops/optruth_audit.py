
import sys
import os
import json
import datetime
from pathlib import Path

# Add project root to sys.path
sys.path.append(os.getcwd())

try:
    from fastapi.testclient import TestClient
    from backend.api_server import app
    from backend.artifacts.io import get_artifacts_root
except ImportError as e:
    print(f"CRITICAL ERROR: Could not import backend modules. Run from repo root. {e}")
    sys.exit(1)

client = TestClient(app)

OUTPUT_DIR = Path("outputs/proofs/d50_optruth_audit_01")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

ENDPOINTS = [
    ("/health_ext", "GET", 200),
    ("/dashboard", "GET", 200),
    ("/context", "GET", 200),
    ("/pulse", "GET", 200),
    ("/foundation", "GET", 404), # Explicit check (foundation vs agms/foundation)
    ("/briefing", "GET", 200),
    ("/aftermarket", "GET", 200),
    ("/news_digest", "GET", 200),
    ("/elite/state", "GET", 200),
    ("/elite/chat", "POST", 200, {"message": "System Status", "context": {}}),
    ("/os/state_snapshot", "GET", 200),
    ("/events/latest", "GET", 200),
    ("/lab/war_room", "GET", 200),
    ("/lab/os/iron/state_history", "GET", 200),
    ("/lab/os/iron/drift", "GET", 200),
    ("/lab/replay/archive/tail", "GET", 200),
    ("/lab/os/self_heal/findings", "GET", 200),
    ("/lab/os/self_heal/before_after", "GET", 200),
]

ARTIFACTS = [
    "outputs/os/state_snapshot.json",
    "outputs/os/os_knowledge_index.json",
    "outputs/ledgers/system_events.jsonl",
    "outputs/ledgers/reliability_ledger_global.jsonl",
    "outputs/os/engine/provider_health.json",
    "outputs/proofs/canon/pending_index_v2.json",
    "outputs/os/canon_debt_radar.json",
    "outputs/os/iron_os_history.json"
]

def audit_endpoints():
    results = []
    print("--- Auditing Endpoints ---")
    for method in ENDPOINTS:
        url = method[0]
        http_method = method[1]
        expected_status = method[2]
        payload = method[3] if len(method) > 3 else None
        
        entry = {
            "endpoint": url,
            "method": http_method,
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "expected_status": expected_status
        }
        
        start = datetime.datetime.now()
        try:
            if http_method == "GET":
                resp = client.get(url)
            elif http_method == "POST":
                resp = client.post(url, json=payload)
            else:
                resp = None
            
            end = datetime.datetime.now()
            latency_ms = (end - start).total_seconds() * 1000
            
            entry["status_code"] = resp.status_code
            entry["latency_ms"] = round(latency_ms, 2)
            
            # Brief check of response
            try:
                data = resp.json()
                entry["payload_keys"] = list(data.keys()) if isinstance(data, dict) else "LIST"
            except:
                entry["payload_keys"] = "INVALID_JSON"

            # Determine Health
            if resp.status_code == expected_status:
                entry["health"] = "HEALTHY"
            elif resp.status_code == 404:
                entry["health"] = "MISSING"
            elif resp.status_code == 500:
                entry["health"] = "CRASH"
            else:
                entry["health"] = f"UNEXPECTED_{resp.status_code}"
                
        except Exception as e:
            entry["status_code"] = -1
            entry["health"] = "CLIENT_ERROR"
            entry["error"] = str(e)
            
        print(f"{http_method} {url} -> {entry['health']} ({entry.get('status_code')})")
        results.append(entry)
        
    with open(OUTPUT_DIR / "01_endpoint_matrix.json", "w") as f:
        json.dump(results, f, indent=2)

def audit_artifacts():
    results = []
    print("\n--- Auditing Artifacts ---")
    repo_root = Path(os.getcwd())
    
    for rel_path in ARTIFACTS:
        full_path = repo_root / rel_path
        entry = {
            "path": rel_path,
            "exists": full_path.exists(),
        }
        
        if full_path.exists():
            entry["size_bytes"] = full_path.stat().st_size
            entry["mtime"] = datetime.datetime.fromtimestamp(full_path.stat().st_mtime).isoformat()
            
            # Check valid JSON
            if rel_path.endswith(".json"):
                try:
                    with open(full_path, "r") as f:
                        json.load(f)
                    entry["valid_json"] = True
                except:
                    entry["valid_json"] = False
        else:
             # Check if generator exists
             entry["generator_guess"] = "UNKNOWN"
             if "state_snapshot" in rel_path: entry["generator_guess"] = "StateSnapshotEngine"
             if "knowledge_index" in rel_path: entry["generator_guess"] = "generate_os_knowledge_index.py"
        
        print(f"{rel_path} -> {'EXISTS' if entry['exists'] else 'MISSING'}")
        results.append(entry)

    with open(OUTPUT_DIR / "02_artifact_audit.json", "w") as f:
        json.dump(results, f, indent=2)

if __name__ == "__main__":
    audit_endpoints()
    audit_artifacts()
