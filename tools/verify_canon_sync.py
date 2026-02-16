#!/usr/bin/env python3
import re
import os
import sys
from pathlib import Path

WAR_CALENDAR_PATH = Path("docs/canon/OMSR_WAR_CALENDAR__35_55_DAYS.md")
SEALS_DIR = Path("outputs/seals")

def verify_sync():
    if not WAR_CALENDAR_PATH.exists():
        print(f"[ERROR] War Calendar not found: {WAR_CALENDAR_PATH}")
        sys.exit(1)

    print(f"Scanning {WAR_CALENDAR_PATH} for seal references...")
    
    with open(WAR_CALENDAR_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    # Regex to find seal links or mentions
    # Matches: `outputs/seals/SEAL_NAME.md`
    matches = re.findall(r"outputs/seals/(SEAL_[\w\d_]+\.md)", content)
    
    print(f"Found {len(matches)} seal references in War Calendar.")
    
    missing_seals = []
    
    for seal_name in matches:
        seal_path = SEALS_DIR / seal_name
        if not seal_path.exists():
            missing_seals.append(seal_name)
    
    if missing_seals:
        print("\n[FAIL] The following seals referenced in War Calendar are MISSING from disk:")
        for s in missing_seals:
            print(f" - {s}")
        print("\nEnsure these files are committed or restore them.")
    else:
        print("[PASS] All referenced seals exist on disk.")

    # Reverse Check: Seals on disk explicitly NOT in War Calendar?
    # This is "Drift" - we want to know about seals that are "Orphaned" from the calendar.
    # We only warn for strict "SEAL_DAY_*" or specific patterns to avoid noise, 
    # but for this audit let's checking everything valid.
    
    print("\nChecking for Orphaned Seals (Disk -> Calendar)...")
    orphaned_seals = []
    
    for root, _, files in os.walk(SEALS_DIR):
        for file in files:
            if file.endswith(".md"):
                if file not in matches:
                    orphaned_seals.append(file)
    
    if orphaned_seals:
        print(f"[WARNING] {len(orphaned_seals)} seals found on disk but NOT referenced in War Calendar.")
        # Print top 5 examples
        for s in orphaned_seals[:5]:
            print(f" - (Orphan) {s}")
        if len(orphaned_seals) > 5: print(f" - ... and {len(orphaned_seals)-5} more.")
        
        # We don't fail the build for this yet, as it might be legacy drift.
        # But we flag it.
    
    if missing_seals:
        sys.exit(1)
    
    sys.exit(0)

if __name__ == "__main__":
    verify_sync()
