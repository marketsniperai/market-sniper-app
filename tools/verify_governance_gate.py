#!/usr/bin/env python3
import subprocess
import sys

SCRIPTS = [
    [sys.executable, "tools/verify_repo_root.py"],
    [sys.executable, "tools/verify_no_stash_artifacts.py"],
    [sys.executable, "tools/verify_artifact_integrity.py"],
    [sys.executable, "tools/verify_canon_sync.py"]
]

def run_gate():
    print("="*60)
    print("ANTIGRAVITY GOVERNANCE GATE")
    print("="*60)
    
    failure = False
    
    for cmd in SCRIPTS:
        print(f"\n>> Executing: {' '.join(cmd)}")
        try:
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError:
            print(f"[FAIL] Command failed: {' '.join(cmd)}")
            failure = True
            # We continue to run others to show full report? 
            # Or strict halt? Constitution says strict.
            print("Strict halt invoked.")
            sys.exit(1)
            
    print("\n" + "="*60)
    print("VERDICT: GOVERNANCE PASS")
    print("="*60)

if __name__ == "__main__":
    run_gate()
