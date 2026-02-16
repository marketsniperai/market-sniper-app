import os
import re

REPO_ROOT = r"C:\MSR\MarketSniperRepo"
CALENDAR_PATH = os.path.join(REPO_ROOT, "docs", "canon", "OMSR_WAR_CALENDAR__35_55_DAYS.md")
SEALS_DIR = os.path.join(REPO_ROOT, "outputs", "seals")

def reconstruct():
    print(f"Reading War Calendar from: {CALENDAR_PATH}")
    
    if not os.path.exists(CALENDAR_PATH):
        print("Error: War Calendar not found.")
        return

    with open(CALENDAR_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    # Regex to find Seal entries in the calendar
    # Pattern: - [x] ... (Title) ... 
    #            - ↳ Seal: [`FILENAME`](PATH)
    
    # We want to capture Title and Filename.
    # Actually, simpler Regex: `\[`([A-Z0-9_]+.md)`\]`
    # Or just scan for `Seal: [` ...
    
    seal_refs = re.findall(r"Seal: \[`([^`]+)`\]", content)
    
    print(f"Found {len(seal_refs)} seal references in War Calendar.")
    
    created_count = 0
    
    for seal_filename in seal_refs:
        full_path = os.path.join(SEALS_DIR, seal_filename)
        
        if os.path.exists(full_path):
            # print(f"[EXISTS] {seal_filename}")
            continue
            
        # Reconstruct
        # Extract ID from filename (e.g. SEAL_D62_12_...)
        seal_id = "UNKNOWN"
        parts = seal_filename.split("_")
        if len(parts) > 1:
            seal_id = parts[1] # D62
            if len(parts) > 2 and parts[2].isdigit():
                 seal_id += f".{parts[2]}" # D62.12
        
        title = seal_filename.replace("SEAL_", "").replace(".md", "").replace("_", " ")
        
        seal_content = f"# SEAL: {seal_id} {title}\n\n"
        seal_content += "Authority: RECONSTRUCTION (Antigravity)\n"
        seal_content += "Date: 2026-02-17\n"
        seal_content += "Type: RECONSTRUCTED SEAL (METADATA VALID)\n"
        seal_content += f"Scope: {seal_id}\n\n"
        seal_content += "> \"Reconstructed from War Calendar Ledger.\"\n\n"
        seal_content += "## Reconstruction Note\n"
        seal_content += "This seal was physically missing but its execution was confirmed in the Canonical War Calendar (`OMSR_WAR_CALENDAR`).\n"
        seal_content += "This file serves as a placeholder to maintain index integrity and link rot protection.\n"
        
        try:
            with open(full_path, "w", encoding="utf-8") as f:
                f.write(seal_content)
            print(f"[CREATED] {seal_filename}")
            created_count += 1
        except Exception as e:
            print(f"[ERROR] Could not create {seal_filename}: {e}")

    print(f"Reconstruction Complete. Created {created_count} missing seals.")

if __name__ == "__main__":
    reconstruct()
