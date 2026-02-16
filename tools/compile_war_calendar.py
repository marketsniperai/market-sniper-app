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
    
    # Sort: Primary = Day (Descending), Secondary = Date (Descending), Tertiary = Filename
    def sort_key(s):
        name = s.get("filename", "")
        date = s.get("date", "1970-01-01")
        # Extract D number (Handle SEAL_D63 and SEAL_DAY_01)
        import re
        match_d = re.search(r"_D(\d+)_", name)
        match_day = re.search(r"_DAY_(\d+)_", name)
        
        day = 0
        if match_d:
            day = int(match_d.group(1))
        elif match_day:
            day = int(match_day.group(1))
            
        return (day, date, name)

    # Reverse=True gives us Descending Day
    seals.sort(key=sort_key, reverse=True)
    
    lines = []
    lines.append("# OMSR WAR CALENDAR (AUTO-GENERATED)")
    lines.append("")
    lines.append(f"> **Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("> **Source:** `outputs/audit/SEAL_INDEX.json`")
    lines.append("> **Authority:** IMMUTABLE (Derived from Seals)")
    lines.append("> **Sorting:** DESCENDING (Newest First)")
    lines.append("")
    lines.append("## Campaign Log")
    lines.append("")
    lines.append("| Day | Date | Seal | Type | Authority | Status |")
    lines.append("| :--- | :--- | :--- | :--- | :--- | :--- |")
    
    for s in seals:
        name = s.get("filename", "UNKNOWN")
        path = s.get("path", "")
        date = s.get("date", "---")
        stype = s.get("type", "---")
        auth = s.get("authority", "---")
        
        # Cleanup Date (remove quotes if any)
        if date: date = date.replace('"', '').replace("'", "")
        
        # Extract Day for display
        import re
        match_d = re.search(r"_D(\d+)_", name)
        match_day = re.search(r"_DAY_(\d+)_", name)
        
        day_str = "---"
        if match_d:
            day_str = f"D{match_d.group(1)}"
        elif match_day:
            day_str = f"D{match_day.group(1)}"
        
        # Link in repo (relative to docs/canon)
        rel_link = f"../../{path}".replace("\\", "/")
        
        lines.append(f"| {day_str} | {date} | [{name}]({rel_link}) | {stype} | {auth} | SEALED |")

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
