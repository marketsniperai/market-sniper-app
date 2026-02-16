import json
import os
import sys
from datetime import datetime

# Paths
ROOT_DIR = os.getcwd()
INDEX_PATH = os.path.join(ROOT_DIR, "outputs", "audit", "SEAL_INDEX.json")
OUTPUT_PATH = os.path.join(ROOT_DIR, "docs", "canon", "OMSR_WAR_CALENDAR_AUTO.md")

def load_index():
    if not os.path.exists(INDEX_PATH):
        print(f"ERROR: Index not found at {INDEX_PATH}")
        sys.exit(1)
    with open(INDEX_PATH, "r") as f:
        return json.load(f)

def generate_calendar(index):
    # Index is a list of dicts
    seals = index if isinstance(index, list) else index.get("seals", [])
    
    # Sort primarily by Day number (DXX), secondarily by filename
    def sort_key(s):
        name = s.get("filename", "")
        # Extract D number
        import re
        match = re.search(r"_D(\d+)_", name)
        day = int(match.group(1)) if match else 999 # Sort unknowns to end
        return (day, name)

    seals.sort(key=sort_key)
    
    lines = []
    lines.append("# OMSR WAR CALENDAR (AUTO-GENERATED)")
    lines.append("")
    lines.append(f"> **Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("> **Source:** `outputs/audit/SEAL_INDEX.json`")
    lines.append("> **Authority:** IMMUTABLE (Derived from Seals)")
    lines.append("")
    lines.append("## Campaign Log")
    lines.append("")
    lines.append("| Day | Seal | Path | Status |")
    lines.append("| :--- | :--- | :--- | :--- |")
    
    for s in seals:
        name = s.get("filename", "UNKNOWN")
        path = s.get("path", "")
        # day_id = s.get("day_id", "Unknown Day")
        
        # Extract Day for display
        import re
        match = re.search(r"_D(\d+)_", name)
        day_str = f"D{match.group(1)}" if match else "---"
        
        # Link in repo (relative to docs/canon)
        # Path in index is relative to repo root (e.g. outputs/seals/...)
        # We need relative link from docs/canon -> ../../outputs/seals/...
        rel_link = f"../../{path}".replace("\\", "/")
        
        lines.append(f"| {day_str} | [{name}]({rel_link}) | `{path}` | SEALED |")

    return "\n".join(lines)

def main():
    print(f"Reading {INDEX_PATH}...")
    index = load_index()
    print(f"Found {len(index)} seals.")
    
    content = generate_calendar(index)
    
    print(f"Writing {OUTPUT_PATH}...")
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w") as f:
        f.write(content)
    print("Done.")

if __name__ == "__main__":
    main()
