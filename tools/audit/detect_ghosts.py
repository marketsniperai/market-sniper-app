import re
from pathlib import Path

ROOT_DIR = Path("c:/MSR/MarketSniperRepo")
OS_MODULES_MD = ROOT_DIR / "docs" / "canon" / "OS_MODULES.md"
EWIMSC_MD = ROOT_DIR / "docs" / "canon" / "EWIMSC.md"

def parse_modules():
    modules = []
    content = OS_MODULES_MD.read_text(encoding="utf-8")
    # | **OS.Infra.API** | API Server | CORE | Entry point... | `/*` | `backend/api_server.py` |
    # Wait, the column count varies or table formatting varies.
    # Looking at the file content from step 451:
    # | **OS.Infra.API** | API Server | CORE | ... | `/*` | `backend/api_server.py` |
    # That's 6 columns? No, let's look at the D-Ref column.
    # In step 451, I see:
    # | **UI.Theme.Typography** | ... | ... | ... | `...` | Canon |
    # The Backend table (lines 25-86) does NOT have a D-Ref column clearly labeled in the header?
    # Line 25: | Module ID | Name | Type | Description | Key Port (Endpoint) | Primary File |
    # It seems the Backend table lacks D-Ref.
    # The UI table (Line 92) HAS D-Ref:
    # | Module ID | Name | Type | Description | Key File | D-Ref |
    
    # Logic:
    # 1. Parse UI Modules (with D-Ref).
    # 2. Parse Backend Modules (without D-Ref, rely on matching name/ID to seal description).
    
    rows = content.splitlines()
    for row in rows:
        if not row.strip().startswith("|") or "---" in row or "Module ID" in row:
            continue
        
        parts = [p.strip() for p in row.split("|")]
        if len(parts) < 3: continue
        
        # Parts[1] is empty because split("|") on "| foo |" gives ["", "foo", ""]
        mid = parts[1].replace("**", "")
        name = parts[2]
        
        d_ref = "N/A"
        # Check if it has D-Ref (last column usually, if table has 6 columns and last one looks like Dxx)
        # UI table has 7 parts (msg empty, ID, Name, Type, Desc, KeyFile, DRef, empty)
        if len(parts) >= 7 and (parts[6].startswith("D") or parts[6] == "Canon"):
            d_ref = parts[6]
            
        modules.append({
            "id": mid,
            "name": name,
            "d_ref": d_ref
        })
    return modules

def parse_seals():
    content = EWIMSC_MD.read_text(encoding="utf-8")
    return content # Just raw content search for now

def detect_ghosts():
    modules = parse_modules()
    seal_content = parse_seals()
    
    ghosts = []
    
    print(f"Scanning {len(modules)} modules for seal coverage...")
    
    for m in modules:
        # 1. Check D-Ref if valid
        if m["d_ref"] not in ["N/A", "Canon", "IMMUTABLE"]:
            # Check if D-Ref exists in seal content
            # clean d-ref: "D56.9" -> "D56.09" or "D56_09"?
            # Just naive search
            d_simple = m["d_ref"].replace(".", "")
            if m["d_ref"] in seal_content or d_simple in seal_content:
                continue # Covered by D-Ref reference
                
        # 2. Check Name/ID in seal content
        # Check if "War Room" appears etc.
        if m["name"] in seal_content or m["id"] in seal_content:
            continue
            
        # 3. If "OS.Infra" (Infrastructure), it might be implicit in "D56.01" etc.
        # But we want explicit claims.
        
        ghosts.append(m)
        
    print(f"Found {len(ghosts)} potential ghosts:")
    for g in ghosts:
        print(f" - [{g['id']}] {g['name']} (D-Ref: {g['d_ref']})")
        
    # Generate Ghost Ledger snippet
    if ghosts:
        with open(ROOT_DIR / "docs" / "canon" / "GHOST_LEDGER.md", "w") as f:
            f.write("# GHOST LEDGER\n\n")
            f.write("| Module ID | Name | Status |\n")
            f.write("| :--- | :--- | :--- |\n")
            for g in ghosts:
                 f.write(f"| **{g['id']}** | {g['name']} | **GHOST** |\n")

if __name__ == "__main__":
    detect_ghosts()
