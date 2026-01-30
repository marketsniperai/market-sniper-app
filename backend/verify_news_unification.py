
import requests
import json
import os
import sys
from pathlib import Path

# Fix sys.path to ensure backend module can be imported
sys.path.append("c:/MSR/MarketSniperRepo")

# Setup paths
BACKEND_DIR = Path("c:/MSR/MarketSniperRepo/backend")
OUTPUTS_DIR = Path("c:/MSR/MarketSniperRepo/outputs")
ARTIFACT_PATH = OUTPUTS_DIR / "engine/news_digest.json"

def verify_news_unification():
    print("--- D47.HF-A News Backend Unification Verification ---")
    
    # 1. Clean Slate
    print("[1] Cleaning existing artifact...")
    if ARTIFACT_PATH.exists():
        os.remove(ARTIFACT_PATH)
        print("    > Artifact removed.")
    else:
        print("    > No existing artifact found (clean).")

    # 2. Query Endpoint
    print("[2] Querying /news_digest endpoint (via python requests)...")
    try:
        # Assuming local API is running, but we can also simulate via direct import if API not up
        # BUT the task says "Verify /news_digest returns 200", implying usually a live check.
        # However, since I cannot easily ensure the API server is strictly running in the background without orchestrating it,
        # I will fall back to DIRECT ENGINE CALL if the request fails, or just test the engine logic which is the core truth.
        # The prompt says: "01_backend_unit_or_smoke.txt (curl or python script showing /news_digest 200)"
        
        # NOTE: In this agent environment, I often don't have a background API running unless I started it.
        # I will rely on unit-test style import verification of the Engine Logic FIRST, 
        # as that guarantees the artifact creation. 
        # Then I will test the API wiring via FastAPI TestClient if possible, or just Engine.
        
        from fastapi.testclient import TestClient
        from backend.api_server import app
        
        client = TestClient(app)
        response = client.get("/news_digest")
        
        if response.status_code == 200:
            print("    > SUCCESS: Endpoint returned 200 OK.")
            data = response.json()
            print(f"    > Response Source: {data.get('source')}")
        else:
            print(f"    > FAIL: Endpoint returned {response.status_code}")
            sys.exit(1)
            
    except Exception as e:
        print(f"    > FAIL: Exception during request: {e}")
        sys.exit(1)

    # 3. Verify Artifact Existence
    print("[3] Verifying production-observable artifact...")
    if ARTIFACT_PATH.exists():
        print("    > SUCCESS: outputs/engine/news_digest.json exists.")
    else:
        print("    > FAIL: Artifact NOT found after request.")
        sys.exit(1)

    # 4. Content Content
    print("[4] Validating artifact content...")
    with open(ARTIFACT_PATH, "r") as f:
        artifact = json.load(f)
        
    items = artifact.get("items", [])
    if len(items) > 0:
        print(f"    > SUCCESS: Found {len(items)} items.")
        print(f"    > Sample Headline: {items[0].get('headline')}")
    else:
        print("    > FAIL: Artifact items list is empty.")
        sys.exit(1)
        
    if artifact.get("status") == "EXISTING":
        print("    > SUCCESS: Status is EXISTING.")
    else:
        print(f"    > FAIL: Status is {artifact.get('status')}")
    
    # 5. Dump Proof
    proof_path = OUTPUTS_DIR / "proofs/day47_hf_a_news_backend_unification"
    proof_path.mkdir(parents=True, exist_ok=True)
    
    with open(proof_path / "01_backend_unit_or_smoke.txt", "w") as f:
        f.write(f"Endpoint Status: {response.status_code}\n")
        f.write(f"Response Body: {json.dumps(data, indent=2)}\n")
        
    with open(proof_path / "02_artifact_exists.txt", "w") as f:
        f.write(f"Artifact Path: {ARTIFACT_PATH}\n")
        f.write(f"Exists: {ARTIFACT_PATH.exists()}\n")
        f.write(f"Size: {ARTIFACT_PATH.stat().st_size} bytes\n")
        
    with open(proof_path / "03_sample_response.json", "w") as f:
        json.dump(artifact, f, indent=2)

    print("--- Verification Complete ---")

if __name__ == "__main__":
    verify_news_unification()
