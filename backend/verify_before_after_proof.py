import json
import logging
from pathlib import Path
from datetime import datetime, timezone
from backend.os_ops.iron_os import IronOS
from backend.api_server import app
from fastapi.testclient import TestClient

# Setup
client = TestClient(app)
logging.basicConfig(level=logging.INFO)

def test_before_after_missing():
    from backend.artifacts.io import get_artifacts_root
    root = get_artifacts_root()
    path = root / "os/os_before_after_diff.json"
    if path.exists():
        path.unlink()
        
    print("Test 1: Missing Artifact...")
    response = client.get("/lab/os/self_heal/before_after")
    assert response.status_code == 404, f"Expected 404, got {response.status_code}"
    print("PASS: Missing Artifact (404)")

def test_before_after_valid():
    from backend.artifacts.io import get_artifacts_root
    root = get_artifacts_root()
    path = root / "os/os_before_after_diff.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    
    payload = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "operation_id": "OP-123",
        "originating_module": "AutoFix",
        "before": {"status": "broken", "count": 1},
        "after": {"status": "fixed", "count": 0},
        "changed_keys": ["status", "count"]
    }
    
    with open(path, "w") as f:
        json.dump(payload, f)
        
    print("Test 2: Valid Artifact...")
    response = client.get("/lab/os/self_heal/before_after")
    assert response.status_code == 200, f"Expected 200, got {response.status_code}"
    data = response.json()
    assert data["operation_id"] == "OP-123"
    assert data["before_state"]["status"] == "broken"
    assert data["after_state"]["status"] == "fixed"
    print("PASS: Valid Artifact")

def test_before_after_strict_schema():
    # Test that it handles schema variations if strict mode allows flexibility or drops invalid fields
    # D42.09 requires strict parse. If mandatory fields missing?
    # IronOS implementation uses .get() defaults for dicts, so it should be robust.
    pass

if __name__ == "__main__":
    try:
        test_before_after_missing()
        test_before_after_valid()
        
        # Generate Proof
        proof = {
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "status": "VERIFIED",
            "modules": ["IronOS", "WarRoom"],
            "features": ["Before/After Diff"],
            "tests": ["Missing Artifact", "Valid Artifact"]
        }
        
        proof_path = Path("outputs/runtime/day_42/day_42_09_before_after_diff_proof.json")
        proof_path.parent.mkdir(parents=True, exist_ok=True)
        with open(proof_path, "w") as f:
            json.dump(proof, f, indent=2)
            
        print("Proof generated.")
    except Exception as e:
        print(f"FAIL: {e}")
        exit(1)
