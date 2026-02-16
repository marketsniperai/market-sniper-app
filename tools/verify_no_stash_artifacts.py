#!/usr/bin/env python3
import subprocess
import sys
import re

FORBIDDEN_PATHS = [
    r"outputs/seals/.*",
    r"outputs/proofs/.*",
    r"docs/canon/.*"
]

def check_stash():
    # List stash content
    try:
        # Get list of stash entries
        result = subprocess.run(["git", "stash", "list"], capture_output=True, text=True)
        stashes = result.stdout.strip().split('\n')
        
        if not stashes or stashes == ['']:
            print("[PASS] No stashes found.")
            return

        print(f"Scanning {len(stashes)} stashes for forbidden artifacts...")
        
        violation_found = False
        
        for stash_line in stashes:
            stash_id = stash_line.split(':')[0]
            # List files in this stash
            files_result = subprocess.run(
                ["git", "stash", "show", "--name-only", stash_id], 
                capture_output=True, 
                text=True
            )
            files = files_result.stdout.strip().split('\n')
            
            for f in files:
                for pattern in FORBIDDEN_PATHS:
                    if re.match(pattern, f):
                        print(f"[VIOLATION] Stash {stash_id} contains forbidden artifact: {f}")
                        violation_found = True
        
        if violation_found:
            # Check for manifest
            if not os.path.exists("STASH_MANIFEST.json"):
                 print("\n[FATAL] Stashed governance artifacts detected WITHOUT STASH_MANIFEST.json.")
                 print("Risk: Silent loss of seals/canon.")
                 sys.exit(1)
            else:
                print("[WARNING] Stashed artifacts found, but STASH_MANIFEST.json exists (Override Acceptable).")

    except Exception as e:
        print(f"Error checking stash: {e}")
        sys.exit(1)

import os
if __name__ == "__main__":
    check_stash()
    print("[PASS] Stash safety check complete.")
