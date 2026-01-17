import json
import logging
import requests
from pathlib import Path
from datetime import datetime, timezone
from backend.os_ops.iron_os import IronOS
from backend.api_server import app
from fastapi.testclient import TestClient

# Setup
client = TestClient(app)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def test_findings_missing_artifact():
    from backend.artifacts.io import get_artifacts_root
    # Ensure missing
    root = get_artifacts_root()
    path = root / IronOS.FINDINGS_SUBPATH
    if path.exists():
        path.unlink()
        
    print("Running Findings Verification...")
    
    # 1. API Call -> 404
    response = client.get("/lab/os/self_heal/findings")
    assert response.status_code == 404, f"Expected 404 for missing artifact, got {response.status_code}"
    print("PASS: Missing Artifact")

def test_findings_valid_artifact():
    from backend.artifacts.io import get_artifacts_root
    root = get_artifacts_root()
    path = root / IronOS.FINDINGS_SUBPATH
    path.parent.mkdir(parents=True, exist_ok=True)
    
    payload = {
        "findings": [
            {
                "finding_code": "FIND-001",
                "severity": "INFO",
                "message": "Routine scan completed",
                "timestamp_utc": datetime.now(timezone.utc).isoformat()
            },
             {
                "finding_code": "FIND-002",
                "severity": "WARN",
                "message": "Minor drift detected",
                "originating_module": "Housekeeper"
            }
        ]
    }
    
    with open(path, "w") as f:
        json.dump(payload, f)
        
    # 2. API Call -> 200 + Content
    response = client.get("/lab/os/self_heal/findings")
    assert response.status_code == 200, f"Expected 200 for valid artifact, got {response.status_code}"
    data = response.json()
    
    assert "findings" in data, "Response missing 'findings' key"
    assert len(data["findings"]) == 2, f"Expected 2 findings, got {len(data.get('findings', []))}. Data: {data}"
    assert data["findings"][0]["finding_code"] == "FIND-001", "Mismatch finding code 1"
    assert data["findings"][1]["severity"] == "WARN", "Mismatch severity 2"
    
    print("PASS: Valid Artifact")

def test_findings_partial_invalid():
    from backend.artifacts.io import get_artifacts_root
    root = get_artifacts_root()
    path = root / IronOS.FINDINGS_SUBPATH
    
    payload = {
        "findings": [
            {
                "finding_code": "FIND-003",
                "severity": "ERROR",
                "message": "Critical issue"
            },
            {
                "finding_code": "FIND-BAD",
                "severity": "CRITICAL", # Invalid enum
                "message": "Should be dropped"
            }
        ]
    }
    
    with open(path, "w") as f:
        json.dump(payload, f)
        
    response = client.get("/lab/os/self_heal/findings")
    assert response.status_code == 200, f"Expected 200 for partial invalid, got {response.status_code}"
    data = response.json()
    
    assert len(data["findings"]) == 1, f"Expected 1 valid finding, got {len(data.get('findings', []))}. Data: {data}"
    assert data["findings"][0]["finding_code"] == "FIND-003", "Mismatch finding code 3"
    
    print("PASS: Partial Invalid")
    
    # Clean up
    if path.exists():
        path.unlink()

if __name__ == "__main__":
    try:
        test_findings_missing_artifact()
        test_findings_valid_artifact()
        test_findings_partial_invalid()
        
        # Generate Proof
        proof = {
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "status": "VERIFIED",
            "modules": ["IronOS", "WarRoom"],
            "features": ["Findings Panel", "Strict Validation"],
            "tests": ["Missing Artifact", "Valid Artifact", "Partial Invalid"]
        }
        
        proof_path = Path("outputs/runtime/day_42/day_42_08_findings_proof.json")
        proof_path.parent.mkdir(parents=True, exist_ok=True)
        with open(proof_path, "w") as f:
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
