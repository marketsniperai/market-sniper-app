import sys
import os

# Add repo root to path
sys.path.append("c:/MSR/MarketSniperRepo")

try:
    from backend.schemas.manifest_schema import RunManifest
    import pydantic
    print(f"Pydantic version: {pydantic.VERSION}")

    data_missing = {
        "run_id": "123",
        "build_id": "b1",
        "timestamp": "t1",
        "status": "OK"
    }

    try:
        print("\n--- TEST 1: Missing keys ---")
        m = RunManifest(**data_missing)
        print("Success with defaults!")
        print(f"Mode: {m.mode}")
        print(f"Window: {m.window}")
    except Exception as e:
        print("Validation Error:")
        print(e)

    data_none = {
        "run_id": "123",
        "build_id": "b1",
        "timestamp": "t1",
        "status": "OK",
        "mode": None,
        "window": None
    }
    try:
        print("\n--- TEST 2: Explicit None ---")
        m = RunManifest(**data_none)
        print("Success with None?")
    except Exception as e:
        print("Validation Error with None:")
        print(e)

except ImportError as e:
    print(f"Import Error: {e}")
except Exception as e:
    print(f"Unexpected Error: {e}")
