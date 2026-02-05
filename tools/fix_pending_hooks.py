import os
import re
from pathlib import Path

ROOT = Path(os.getcwd())
SEALS_DIR = ROOT / "outputs/seals"

HOOK_TEMPLATE = """
## Pending Closure Hook
- Resolved Pending Items:
  - None
- New Pending Items:
  - None
"""

ENFORCEMENT_DATE = "2026-01-28"

def scan_and_fix():
    print(f"Scanning {SEALS_DIR}...")
    count = 0
    if not SEALS_DIR.exists():
        print("Seals dir missing!")
        return

    for file in SEALS_DIR.glob("SEAL_*.md"):
        try:
            content = file.read_text(encoding="utf-8")
            
            # Check date
            date_match = re.search(r'\*\*Date:\s*\*\*\s*(\d{4}-\d{2}-\d{2})', content)
            if not date_match:
                continue
            
            file_date = date_match.group(1)
            if file_date < ENFORCEMENT_DATE:
                continue
            
            # Check hook
            if "## Pending Closure Hook" in content:
                continue
                
            print(f"Fixing {file.name} ({file_date})...")
            with open(file, "a", encoding="utf-8") as f:
                f.write(HOOK_TEMPLATE)
            count += 1
            
        except Exception as e:
            print(f"Error processing {file.name}: {e}")

    print(f"Fixed {count} files.")

if __name__ == "__main__":
    scan_and_fix()
