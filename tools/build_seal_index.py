#!/usr/bin/env python3
import os
import json
import re
from pathlib import Path
from datetime import datetime

# CONFIG
SEALS_DIR = Path("outputs/seals")
OUTPUT_FILE = Path("outputs/audit/SEAL_INDEX.json")

def parse_seal_filename(filename):
    """
    Parses SEAL_DAY_XX_... or SEAL_DXX_...
    """
    # Regex for SEAL_DAY_00_...
    match_day = re.match(r"SEAL_DAY_(\d+)_", filename)
    if match_day:
        return f"Day {match_day.group(1)}"
    
    # Regex for SEAL_DXX_...
    match_d = re.match(r"SEAL_D(\d+)_", filename)
    if match_d:
        return f"Day {match_d.group(1)}"
        
    return "Unknown Day"

def scan_seals():
    if not SEALS_DIR.exists():
        print(f"ERROR: {SEALS_DIR} does not exist.")
        return []

    seal_index = []
    
    print(f"Scanning {SEALS_DIR}...")
    
    for entry in os.scandir(SEALS_DIR):
        if entry.is_file() and entry.name.endswith(".md") and entry.name.startswith("SEAL_"):
            day_id = parse_seal_filename(entry.name)
            
            # Read first few lines for summary/title if needed, 
            # but for now we just index the filename and path.
            seal_data = {
                "filename": entry.name,
                "path": str(Path(entry.path).as_posix()),
                "day_id": day_id,
                "indexed_at": datetime.now().isoformat()
            }
            seal_index.append(seal_data)

    # Sort by Day/Filename
    seal_index.sort(key=lambda x: x['filename'])
    return seal_index

def main():
    # 1. Enforce Root Anchor
    # (Simplified check)
    if not os.path.exists(".git"):
        print("ERROR: Must run from repository root.")
        exit(1)

    # 2. Scan
    index = scan_seals()
    
    # 3. Write
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w") as f:
        json.dump(index, f, indent=2)
        
    print(f"[SUCCESS] Indexed {len(index)} seals to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
