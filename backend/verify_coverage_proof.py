import os
import json
from pathlib import Path
from backend.os_ops.iron_os import IronOS
from backend.api_server import app
from fastapi.testclient import TestClient

client = TestClient(app)

def test_coverage_missing_artifact():
    # Setup: Ensure artifact does NOT exist
    root = Path("outputs")
    path = root / IronOS.COVERAGE_SUBPATH
    if path.exists():
        path.unlink()
        
    # Check IronOS
    snap = IronOS.get_coverage_report()
    assert snap is None, "Should return None if artifact missing"
    
    # Check API
    response = client.get("/lab/os/self_heal/coverage")
    assert response.status_code == 404, "API should 404 if missing"

def test_coverage_valid_artifact():
    from backend.artifacts.io import get_artifacts_root
    print(f"DEBUG: Artifacts Root: {get_artifacts_root()}")
    # Setup: Write valid artifact
    root = Path("outputs")
    path = root / IronOS.COVERAGE_SUBPATH
    print(f"DEBUG: Writing to: {path.resolve()}")
    path.parent.mkdir(parents=True, exist_ok=True)
    
    payload = {
        "entries": [
            {"capability": "AutoFix", "status": "AVAILABLE"},
            {"capability": "Housekeeper", "status": "DEGRADED", "reason": "Drift detected"},
            {"capability": "SafetyNet", "status": "UNAVAILABLE", "reason": "Disabled"}
        ]
    }
    with open(path, "w") as f:
        json.dump(payload, f)
        
    # Check IronOS
    snap = IronOS.get_coverage_report()
    assert snap is not None
    assert len(snap["entries"]) == 3
    assert snap["entries"][0]["capability"] == "AutoFix"
    assert snap["entries"][0]["status"] == "AVAILABLE"
    
    # Check API
    response = client.get("/lab/os/self_heal/coverage")
    assert response.status_code == 200
    data = response.json()
    assert len(data["entries"]) == 3

def test_coverage_partial_invalid():
    # Setup: Mixed valid/invalid
    root = Path("outputs")
    path = root / IronOS.COVERAGE_SUBPATH
    path.parent.mkdir(parents=True, exist_ok=True)
    
    payload = {
        "entries": [
            {"capability": "ValidOne", "status": "AVAILABLE"},
            {"capability": "BadStatus", "status": "KINDA_OK"}, # Invalid status
            {"missing_status": "True"} # Missing status
        ]
    }
    with open(path, "w") as f:
        json.dump(payload, f)
        
    # Check IronOS
    snap = IronOS.get_coverage_report()
    assert snap is not None
    # Only 1 valid entry should remain
    assert len(snap["entries"]) == 1
    assert snap["entries"][0]["capability"] == "ValidOne"


if __name__ == "__main__":
    # Manual run for proof generation
    try:
        print("Running Coverage Verification...")
        test_coverage_missing_artifact()
        print("PASS: Missing Artifact")
        test_coverage_valid_artifact()
        print("PASS: Valid Artifact")
        test_coverage_partial_invalid()
        print("PASS: Partial Invalid")
        
        # Generate Proof Artifact
        proof = {
            "timestamp_utc": "2026-01-17T17:35:00Z", # Approx
            "tests": ["Missing Artifact", "Valid Artifact", "Partial Invalid"],
            "result": "PASS",
            "compliance": "STRICT_LENS"
        }
        
        out_dir = Path("outputs/runtime/day_42")
        out_dir.mkdir(parents=True, exist_ok=True)
        with open(out_dir / "day_42_02_coverage_proof.json", "w") as f:
            json.dump(proof, f, indent=2)
            
        print("Proof generated.")
        
    except AssertionError as e:
        import traceback
        traceback.print_exc()
        print(f"FAIL: {e}")
        exit(1)
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"ERROR: {e}")
        exit(1)
