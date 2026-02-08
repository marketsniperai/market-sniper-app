import json
import os
import re

# Add repo root to path
import sys
sys.path.append(os.getcwd())

TARGET_DIR = "market_sniper_app/lib"

# Keywords to identify "Command Center" surfaces (Screens, Widgets, Repos)
SURFACE_KEYWORDS = [
    r"WarRoom", r"FounderWarRoom", r"TruthMode", r"TruthDebugPanel", 
    r"CommandCenter", r"EliteHub", r"Elite", r"OS", r"Integrity"
]

# Regex for endpoints
# Matches: "/lab/...", "/elite/...", "/api/...", or "/healthz" etc.
# But we focus on the specific paths mentioned in Ledger or common patterns.
ENDPOINT_REGEX = r"['\"](\/(?:lab|elite|api|agms|os|health|ready|dashboard|pulse|context|verify|admin)[^\s'\"]*)['\"]"

def scan_frontend():
    print(f"Scanning Frontend Surface: {TARGET_DIR} ...")
    
    surfaces = []
    
    for root, dirs, files in os.walk(TARGET_DIR):
        for file in files:
            if not file.endswith(".dart"):
                continue
                
            path = os.path.join(root, file)
            # Normalized path for checking
            rel_path = os.path.relpath(path, os.getcwd()).replace("\\", "/")
            
            with open(path, "r", encoding="utf-8") as f:
                try:
                    content = f.read()
                except:
                    continue
            
            # 1. Check if it's a Command Center Surface
            is_surface = False
            matched_keywords = []
            
            # Check Filename
            for k in SURFACE_KEYWORDS:
                if re.search(k, file, re.IGNORECASE):
                    is_surface = True
                    matched_keywords.append(k)
            
            # Check Class Definitions (if not found in filename)
            if not is_surface:
                class_matches = re.findall(r"class\s+(\w+)", content)
                for cls in class_matches:
                    for k in SURFACE_KEYWORDS:
                        if re.search(k, cls, re.IGNORECASE):
                            is_surface = True
                            matched_keywords.append(f"Class:{k}")
                            
            # If not a surface/relevant file, skip deep scanning?
            # User wants "Inventory of Command Center surfaces".
            # If a file is NOT a CC surface but contains CC endpoints, strictly speaking it's not a CC surface, 
            # but maybe a shared repo.
            # If filename has "Repository" and used by CC, good to know.
            # Let's map ALL files that have endpoints, but flag "is_surface"
            
            # 2. Extract Endpoints
            found_endpoints = set(re.findall(ENDPOINT_REGEX, content))
            
            # Only record if it's a surface OR has relevant endpoints
            if is_surface or found_endpoints:
                 surfaces.append({
                    "file": rel_path,
                    "is_cc_surface": is_surface,
                    "keywords": list(set(matched_keywords)),
                    "endpoints": list(found_endpoints)
                 })
                 
    # Deduplicate / Sort
    surfaces.sort(key=lambda x: x["file"])
    
    print(f"Found {len(surfaces)} relevant frontend files.")
    
    output_path = "outputs/proofs/D60_1_COMMAND_CENTER/frontend_surface.json"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(surfaces, f, indent=2)
        
    print(f"Saved frontend surface to {output_path}")

if __name__ == "__main__":
    scan_frontend()
