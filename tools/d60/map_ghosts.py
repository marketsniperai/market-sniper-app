import json
import os
from difflib import get_close_matches

# Configuration
TRIAGE_JSON = "outputs/proofs/D60_3_GHOST_REMEDIATION/ghost_triage.json"
BACKEND_JSON = "outputs/proofs/D60_2_FRONTEND_GHOST_SWEEP/backend_routes.json"
OUTPUT_JSON = "outputs/proofs/D60_3_GHOST_REMEDIATION/ghost_mapping.json"

def main():
    if not os.path.exists(TRIAGE_JSON) or not os.path.exists(BACKEND_JSON):
        print("Missing input files.")
        return

    with open(TRIAGE_JSON, "r", encoding="utf-8") as f:
        triage = json.load(f)
        
    with open(BACKEND_JSON, "r", encoding="utf-8") as f:
        backend_routes = json.load(f) # List of route objects or dict? 
        # Actually structure was {path: [methods]} in D60.2 export
        
    unique_ghosts = triage["unique_true_ghost_paths"]
    existing_paths = list(backend_routes.keys())
    
    mapping = []
    
    for ghost in unique_ghosts:
        # Strategy 1: Exact Match (Logic Error?)
        if ghost in existing_paths:
            action = "INVESTIGATE"
            target = ghost
            reason = "Endpoint exists in backend but was flagged as ghost? Check method mismatch."
        else:
            # Strategy 2: Fuzzy Match / Suffix Match
            # Check for close matches
            matches = get_close_matches(ghost, existing_paths, n=1, cutoff=0.6)
            
            if matches:
                action = "REWIRE_CANDIDATE"
                target = matches[0]
                reason = f"Similar endpoint found: {target}"
            else:
                action = "IMPLEMENT"
                target = None
                reason = "No similar endpoint found."
                
        mapping.append({
            "ghost": ghost,
            "action": action,
            "target": target,
            "reason": reason
        })
        
    os.makedirs(os.path.dirname(OUTPUT_JSON), exist_ok=True)
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(mapping, f, indent=2)
        
    print(f"Mapped {len(mapping)} ghosts.")
    for m in mapping:
        print(f"{m['ghost']} -> {m['action']} ({m['target']})")

if __name__ == "__main__":
    main()
