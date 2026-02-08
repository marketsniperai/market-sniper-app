import json
import os
import re

INPUT_JSON = "outputs/proofs/D60_2_FRONTEND_GHOST_SWEEP/ghost_endpoints.json"
OUTPUT_JSON = "outputs/proofs/D60_3_GHOST_REMEDIATION/ghost_triage.json"

# Known False Positives (Flutter Routes)
FLUTTER_ROUTES = [
    "/welcome", "/startup", "/war_room", "/home", "/dashboard", "/login"
]

def is_false_positive(ghost):
    raw = ghost["raw"]
    path_norm = ghost["path_norm"]
    
    # 1. Check for Flutter Routes
    if path_norm in FLUTTER_ROUTES:
        return True, "Flutter Navigation Route"
        
    # 2. Check for File Imports (contains .dart or starts with ..)
    if ".dart" in raw or raw.startswith(".."):
        return True, "File Import/Path"
        
    # 3. Check for obvious non-endpoints
    if " " in raw:
        return True, "Invalid Space in Path"
        
    return False, None

def main():
    if not os.path.exists(INPUT_JSON):
        print(f"Error: {INPUT_JSON} not found.")
        return

    with open(INPUT_JSON, "r", encoding="utf-8") as f:
        ghosts = json.load(f)
        
    triage = {
        "false_positives": [],
        "true_ghosts": []
    }
    
    print(f"Triaging {len(ghosts)} ghosts...")
    
    for g in ghosts:
        is_fp, reason = is_false_positive(g)
        g["triage_reason"] = reason
        
        if is_fp:
            triage["false_positives"].append(g)
        else:
            triage["true_ghosts"].append(g)
            
    # Deduplicate True Ghosts
    unique_true_ghosts = {}
    for g in triage["true_ghosts"]:
        path = g["path_norm"]
        if path not in unique_true_ghosts:
            unique_true_ghosts[path] = []
        unique_true_ghosts[path].append(g)
        
    triage["unique_true_ghost_paths"] = list(unique_true_ghosts.keys())
    
    os.makedirs(os.path.dirname(OUTPUT_JSON), exist_ok=True)
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(triage, f, indent=2)
        
    print(f"Triaged: {len(triage['false_positives'])} FP / {len(triage['true_ghosts'])} True Ghosts ({len(unique_true_ghosts)} unique).")
    print(f"True Ghosts: {triage['unique_true_ghost_paths']}")

if __name__ == "__main__":
    main()
