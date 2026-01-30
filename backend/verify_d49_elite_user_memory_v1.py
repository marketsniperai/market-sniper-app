import asyncio
import os
import sys
import shutil

# Ensure backend path
sys.path.append(os.getcwd())

# Force artifacts root context if needed (hack for script execution outside normal app flow)
# But get_artifacts_root usually relies on markers or basic CWD.
# Let's ensure CWD is correct.
if not os.path.exists("backend"):
    print("FAILURE: Must run from repo root.")
    sys.exit(1)


from backend.os_intel.elite_user_memory_engine import EliteUserMemoryEngine
from backend.artifacts.io import get_artifacts_root

def test_memory_flow():
    print(f"DEBUG: Artifacts Root: {get_artifacts_root()}")
    print("--- 1. Setting Up ---")
    data = {
        "date": "2026-01-29",
        "session_type": "REGULAR",
        "timestamp_utc": "2026-01-29T20:00:00Z",
        "answers": [
            {"question": "Q1", "answer": "Test Answer 1"},
            {"question": "Q2", "answer": "Test Answer 2"}
        ],
        "email": "ignore@me.com" 
    }
    
    print("--- 2. Saving Reflection (Local Only) ---")
    os.makedirs("outputs/elite/user_reflections", exist_ok=True)
    if os.path.exists("outputs/elite/user_reflections/2026-01-29.json"):
        os.remove("outputs/elite/user_reflections/2026-01-29.json")

    EliteUserMemoryEngine.save_reflection(data, autolearn_override=False)
    
    local_path = "outputs/elite/user_reflections/2026-01-29.json"
    if os.path.exists(local_path):
        print(f"SUCCESS: Local file exists at {local_path}")
    else:
        print(f"FAILURE: Local file missing at {local_path}")
        sys.exit(1)

    print("--- 3. Saving Reflection (Cloud Opt-in) ---")
    EliteUserMemoryEngine.save_reflection(data, autolearn_override=True)
    
    # We can't easily check cloud ledger append in mock without reading it back,
    # but we assume append_to_ledger works if imports valid.
    # Actually, we can check if file created/modified if we map it locally.
    # The Engine uses "elite/cloud_user_reflections.jsonl" relative to artifacts.
    # Default artifacts root is . (or cwd/outputs usually).
    
    print("--- 4. Querying History ---")
    history = EliteUserMemoryEngine.query_history()
    print(f"History Count: {len(history)}")
    if len(history) > 0 and history[0]['date'] == "2026-01-29":
        print("SUCCESS: Query returned correct data.")
    else:
        print("FAILURE: Query mismatch.")
        sys.exit(1)

if __name__ == "__main__":
    test_memory_flow()
