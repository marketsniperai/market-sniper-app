
import sys
import os

# Add repo root to path
sys.path.append(os.getcwd())

from backend.os_ops.state_snapshot_engine import StateSnapshotEngine

def verify():
    schema = StateSnapshotEngine.SYSTEM_STATE_SCHEMA
    total = 0
    print("--- Module Count Verification ---")
    keys = []
    for section, modules in schema.items():
        count = len(modules)
        print(f"{section}: {count}")
        total += count
        keys.extend(modules.keys())
    
    print(f"Total Modules: {total}")
    
    # Check for duplicates
    if len(keys) != len(set(keys)):
        print("WARNING: Duplicate keys found!")
    else:
        print("No duplicates.")
        
    # Check Alpha Vantage
    if "OS.Data.Provider.AlphaVantage" in keys:
        print("Alpha Vantage: FOUND")
    else:
        print("Alpha Vantage: MISSING")

if __name__ == "__main__":
    verify()
