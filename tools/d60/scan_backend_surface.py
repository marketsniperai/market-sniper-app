import json
import os
import re
from fastapi.routing import APIRoute

# Add repo root to path
import sys
sys.path.append(os.getcwd())

from backend.api_server import app

KEYWORDS = [
    "war_room", "iron", "replay", "self_heal", 
    "housekeeper", "autofix", "tuning", "elite",
    "lab", "blackbox", "immune", "dojo"
]

def parse_zombie_ledger(ledger_path):
    ledger_map = {}
    with open(ledger_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    # Parse Markdown Table
    # | Class | Method | Path | Expect | Names |
    
    for line in lines:
        if not line.strip().startswith("|"):
            continue
        if "Class" in line and "Method" in line:
            continue
        if ":---" in line:
            continue
            
        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 6:
            continue
            
        # parts[0] is empty (before first |)
        classification = parts[1].replace("**", "")
        method = parts[2].replace("`", "")
        path = parts[3].replace("`", "")
        # expect = parts[4]
        # names = parts[5]
        
        ledger_map[(method, path)] = classification
        
    return ledger_map

def main():
    print("Scanning Backend Surface via FastAPI Introspection...")
    
    routes = []
    
    for route in app.routes:
        if isinstance(route, APIRoute):
            path = route.path
            methods = list(route.methods)
            name = route.name
            
            # Filter for Command Center Keywords
            if not any(k in path for k in KEYWORDS):
                continue
                
            for method in methods:
                routes.append({
                    "path": path,
                    "method": method,
                    "name": name,
                    "function": route.endpoint.__name__
                })

    print(f"Found {len(routes)} Command Center relevant routes.")
    
    # Load Zombie Ledger
    ledger_path = "docs/canon/ZOMBIE_LEDGER.md"
    ledger_map = parse_zombie_ledger(ledger_path)
    print(f"Loaded {len(ledger_map)} entries from Zombie Ledger.")
    
    # Enriched Data
    enriched_routes = []
    missing_ledger = []
    
    for r in routes:
        key = (r["method"], r["path"])
        classification = ledger_map.get(key)
        
        if not classification:
            # Try finding without trailing slash or similar nuances if needed
            # For now strict match
            missing_ledger.append(f"{r['method']} {r['path']}")
            classification = "UNKNOWN_ZOMBIE"
            
        enriched_routes.append({
            **r,
            "classification": classification
        })
        
    if missing_ledger:
        print(f"WARNING: {len(missing_ledger)} routes missing from Zombie Ledger!")
        for m in missing_ledger:
            print(f" - {m}")
            
    output_path = "outputs/proofs/D60_1_COMMAND_CENTER/backend_surface.json"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(enriched_routes, f, indent=2)
        
    print(f"Saved backend surface to {output_path}")

if __name__ == "__main__":
    main()
