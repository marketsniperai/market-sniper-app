import json
from pathlib import Path
from backend.os_ops.iron_os import IronOS
from backend.artifacts.io import get_artifacts_root

def debug():
    root = get_artifacts_root()
    path = root / IronOS.FINDINGS_SUBPATH
    print(f"Artifact Path: {path}")
    
    # 1. Create Valid Artifact
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "findings": [
            {
                "finding_code": "FIND-DEBUG",
                "severity": "INFO", 
                "message": "Debug Message"
            }
        ]
    }
    with open(path, "w") as f:
        json.dump(payload, f)
        
    print("Artifact created.")
    
    # 2. Call IronOS.get_findings directly (Bypass API for now to test logic)
    print("Calling IronOS.get_findings()...")
    result = IronOS.get_findings()
    print(f"Result: {result}")
    
    if result and len(result['findings']) == 1:
        print("PASS: IronOS Logic")
    else:
        print("FAIL: IronOS Logic")

if __name__ == "__main__":
    debug()
