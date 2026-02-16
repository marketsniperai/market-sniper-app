import json
import os
import sys
from pathlib import Path
from datetime import datetime

# Setup paths
ROOT = Path(os.getcwd())
sys.path.append(str(ROOT))

# Setup paths
ROOT = Path(os.getcwd())
sys.path.append(str(ROOT))

from backend.artifacts.io import get_artifacts_root
ARTIFACTS_ROOT = get_artifacts_root()
FULL = ARTIFACTS_ROOT / "full"
OS_OPS = ARTIFACTS_ROOT / "os/ops"

FULL.mkdir(parents=True, exist_ok=True)
OS_OPS.mkdir(parents=True, exist_ok=True)

# 1. Create a mock misfire_report.json with diagnostics
from backend.artifacts.io import get_artifacts_root
print(f"DEBUG: Engine Artifacts Root: {get_artifacts_root()}")

misfire_report = {
    "status": "MISFIRE",
    "timestamp_utc": datetime.utcnow().isoformat() + "Z",
    "reason": "Simulated Misfire",
    "diagnostics": {
        "root_cause": "TIMEOUT",
        "tier2_signals": [
            {"step": "CheckDB", "result": "OK"},
            {"step": "CheckAPI", "result": "FAIL"}
        ]
    }
}

with open(FULL / "misfire_report.json", "w") as f:
    json.dump({"success": True, "data": misfire_report}, f)

print("Created mock misfire_report.json")

# 2. Run StateSnapshotEngine
try:
    from backend.os_ops.state_snapshot_engine import StateSnapshotEngine
    print("Generating System State...")
    state = StateSnapshotEngine.generate_system_state()
    
    # 3. Verify Misfire Embedding
    misfire = state["ops"]["OS.Ops.Misfire"]
    diag = misfire["meta"]["diagnostics"]
    
    print("\n--- DEBUG ---")
    print(f"Raw Misfire State: {json.dumps(misfire, indent=2)}")

    print("\n--- VERIFICATION ---")
    print(f"Misfire Status: {misfire['status']}")
    print(f"Diagnostics Found: {diag is not None}")
    print(f"Root Cause: {diag.get('root_cause')}")
    print(f"Tier 2 Signals: {len(diag.get('tier2_signals', []))}")
    
    if diag.get("root_cause") == "TIMEOUT" and len(diag.get("tier2_signals")) == 2:
        print("\nSUCCESS: Misfire diagnostics correctly embedded in system_state.json")
    else:
        print("\nFAILURE: Diagnostics mismatch")
        sys.exit(1)

except Exception as e:
    print(f"\nERROR: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
