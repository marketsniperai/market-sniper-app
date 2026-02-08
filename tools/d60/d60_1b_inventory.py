import os
import re
import json
import sys
import fnmatch
from typing import Set, List, Dict, Any, Tuple

# Enable backend imports
sys.path.append(os.getcwd())

try:
    from backend.api_server import app
    from fastapi.routing import APIRoute
except ImportError as e:
    print(f"CRITICAL: Failed to import backend.api_server: {e}")
    sys.exit(1)

# Configuration
FRONTEND_ROOT = "market_sniper_app/lib"
OUTPUT_DIR = "outputs/proofs/D60_1_COMMAND_CENTER"
LEDGER_PATH = "docs/canon/ZOMBIE_LEDGER.md"

# Regex Patterns
STRING_LITERAL_REGEX = re.compile(r"['\"](\/(?:(?!\s).)*?)['\"]")
PARAM_REGEX = re.compile(r"[:$]\{?(\w+)\}?")
WIDGET_CLASS_REGEX = re.compile(r"class\s+(\w+)\s+extends\s+(?:StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget)")

# ------------------------------------------------------------------------------
# 1. Normalization
# ------------------------------------------------------------------------------
def normalize_path(path: str) -> str:
    if "?" in path:
        path = path.split("?")[0]
        
    if "apiBaseUrl" in path or "$baseUrl" in path:
        path = re.sub(r"^\$\{?[^}]+\}?/?", "/", path)
        
    path = re.sub(r"//+", "/", path)
    path = PARAM_REGEX.sub("{param}", path)
    
    if path.endswith("/") and len(path) > 1:
        path = path[:-1]
        
    return path

# ------------------------------------------------------------------------------
# 2. Backend Routes (Step 1)
# ------------------------------------------------------------------------------
def extract_backend_routes() -> Dict[str, Dict[str, Any]]:
    print("Step 1: Introspecting Backend...")
    routes = {} 
    
    for route in app.routes:
        if isinstance(route, APIRoute):
            path = route.path
            path_norm = normalize_path(path)
            methods = list(route.methods)
            name = route.name
            
            # Detect Tier
            tier = "PUBLIC_PRODUCT"
            if path_norm.startswith("/lab/") or path_norm.startswith("/blackbox/") or path_norm.startswith("/immune/") or path_norm.startswith("/dojo/"):
                 tier = "LAB_INTERNAL"
                 # Note: PublicSurfaceShieldMiddleware covers more, but this is a solid heuristic for classification
            elif path_norm.startswith("/elite/"):
                 tier = "ELITE_GATED"
                 
            # Note: Checking Require Elite/Founder dependency is hard via introspection without inspecting the function signature/dependencies deeply.
            # Using path convention + hardcoded rules for now as primary signal.
            
            routes[path_norm] = {
                "path": path,
                "path_norm": path_norm,
                "methods": methods,
                "name": name,
                "inferred_tier": tier
            }
            
    print(f"Extracted {len(routes)} unique backend routes.")
    return routes

# ------------------------------------------------------------------------------
# 3. Canon Classification (Step 2)
# ------------------------------------------------------------------------------
def parse_zombie_ledger() -> Dict[str, Dict[str, Any]]:
    print("Step 2: Parsing Zombie Ledger...")
    ledger = {}
    
    if not os.path.exists(LEDGER_PATH):
        print("CRITICAL: Ledger not found.")
        sys.exit(1)
        
    with open(LEDGER_PATH, "r", encoding="utf-8") as f:
        lines = f.readlines()
        
    for line in lines:
        if not line.strip().startswith("|") or "Class" in line or ":---" in line:
            continue
            
        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 6: continue
        
        tier = parts[1].replace("**", "").strip()
        method = parts[2].replace("`", "").strip()
        path = parts[3].replace("`", "").strip()
        names = parts[5].replace("`", "").strip()
        
        path_norm = normalize_path(path)
        
        if path_norm not in ledger:
            ledger[path_norm] = {
                "tier": tier,
                "methods": set(),
                "path_norm": path_norm,
                "names": names
            }
        ledger[path_norm]["methods"].add(method)
            
    print(f"Parsed {len(ledger)} unique ledger routes.")
    return ledger

# ------------------------------------------------------------------------------
# 4. Frontend Surfaces (Step 3)
# ------------------------------------------------------------------------------
def scan_surfaces() -> List[Dict[str, Any]]:
    print("Step 3: Scanning Frontend Surfaces...")
    surfaces = []
    
    # Identifiers for Command Center Surfaces
    SURFACE_MARKERS = [
        "WarRoom", "Founder", "CommandCenter", "Elite", 
        "Iron", "Replay", "SelfHeal", "Housekeeper", "AutoFix", "Tuning", "Integrity",
        "Dashboard", "Console" # Broadening to capture all potential admin/elite areas
    ]
    
    for root, _, files in os.walk(FRONTEND_ROOT):
        for file in files:
            if not file.endswith(".dart"): continue
            
            path = os.path.join(root, file)
            rel_path = os.path.relpath(path, os.getcwd()).replace("\\", "/")
            
            # Simple check: Is this file likely a surface?
            is_surface = False
            found_markers = []
            
            # Check filename
            for m in SURFACE_MARKERS:
                if m.lower() in file.lower():
                    is_surface = True
                    found_markers.append(m)
                    
            if not is_surface: continue
            
            try:
                with open(path, "r", encoding="utf-8") as f:
                    content = f.read()
            except: continue
            
            # Extract Classes
            classes = WIDGET_CLASS_REGEX.findall(content)
            if not classes and "ab/war_room" not in rel_path and "screens/" not in rel_path:
                 # If no widgets and not in specific folders, might just be logic
                 continue
                 
            # Find Repository Usages
            repos = re.findall(r"(\w+Repository)", content)
            
            surfaces.append({
                "file": rel_path,
                "markers": list(set(found_markers)),
                "classes": classes,
                "repos_used": list(set(repos))
            })
            
    print(f"Identify {len(surfaces)} Command Center related surfaces.")
    return surfaces

# ------------------------------------------------------------------------------
# 5. Frontend Endpoints (Step 4)
# ------------------------------------------------------------------------------
def scan_endpoint_calls() -> List[Dict[str, Any]]:
    print("Step 4: Scanning Frontend Endpoint Calls...")
    calls = []
    
    # Files to scan: Repositories and API Clients logic primarily
    # Also scan the surfaces themselves for direct calls (rare but possible)
    
    for root, _, files in os.walk(FRONTEND_ROOT):
        for file in files:
            if not file.endswith(".dart"): continue
            
            path = os.path.join(root, file)
            rel_path = os.path.relpath(path, os.getcwd()).replace("\\", "/")
            
            # Tactic: Look for strings starting with / inside known IO patterns
            # Or just all strings starting with / like Ghost Sweep, but filter strictly
            
            try:
                with open(path, "r", encoding="utf-8") as f:
                    lines = f.readlines()
            except: continue
            
            for i, line in enumerate(lines):
                stripped = line.strip()
                if stripped.startswith("import ") or stripped.startswith("export "): continue
                if stripped.startswith("//"): continue # Skip comments
                
                matches = STRING_LITERAL_REGEX.findall(line)
                for raw in matches:
                     # Filter
                    if " " in raw or "\n" in raw: continue
                    if raw.startswith(".."): continue # File path
                    if raw.startswith("/assets") or raw.startswith("/icons"): continue
                    
                    # Skip known Flutter routes if not relevant to API (Ghost Sweep list)
                    # Ideally we differentiate. 
                    # For Inventory, we want API calls.
                    # API calls usually in Repos.
                    
                    # Heuristic: If file is Repository or Client, assume it's an API call or Model field.
                    # If it's a Screen, it's likely a Route, UNLESS it's passed to an API function.
                    
                    is_repo_or_client = "repository" in rel_path.lower() or "client" in rel_path.lower() or "service" in rel_path.lower()
                    
                    if not is_repo_or_client:
                        # Skip if it looks like a flutter route
                         if raw in ["/welcome", "/startup", "/war_room", "/home", "/dashboard", "/login"]:
                             continue
                    
                    path_norm = normalize_path(raw)
                    
                    calls.append({
                        "raw": raw,
                        "path_norm": path_norm,
                        "file": rel_path,
                        "line": i + 1,
                        "snippet": stripped
                    })
                    
    print(f"Found {len(calls)} endpoint references.")
    return calls

# ------------------------------------------------------------------------------
# 6. Join & Inventory (Step 5)
# ------------------------------------------------------------------------------
def generate_inventory():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    backend = extract_backend_routes()
    ledger = parse_zombie_ledger()
    surfaces = scan_surfaces()
    calls = scan_endpoint_calls()
    
    # Save Intermediate
    with open(f"{OUTPUT_DIR}/backend_routes.json", "w") as f: json.dump(backend, f, indent=2)
    with open(f"{OUTPUT_DIR}/canon_routes.json", "w") as f: json.dump(ledger, f, default=list, indent=2)
    with open(f"{OUTPUT_DIR}/frontend_surfaces.json", "w") as f: json.dump(surfaces, f, indent=2)
    with open(f"{OUTPUT_DIR}/frontend_endpoint_calls.json", "w") as f: json.dump(calls, f, indent=2)
    
    inventory = {
        "surfaces": surfaces,
        "endpoints": {},
        "verification": {
            "ghosts": [],
            "unclassified": [],
            "ledger_backend_mismatch": []
        }
    }
    
    # Map Calls -> Backend/Ledger
    unique_paths = set(c["path_norm"] for c in calls)
    
    for path in unique_paths:
        # Find usage locations
        usages = [c["file"] for c in calls if c["path_norm"] == path]
        
        # Check Backend
        backend_info = backend.get(path)
        ledger_info = ledger.get(path)
        
        status = "OK"
        if not backend_info:
            status = "GHOST"
            inventory["verification"]["ghosts"].append(path)
        elif not ledger_info:
             status = "UNCLASSIFIED"
             inventory["verification"]["unclassified"].append(path)
             
        # Merge Tier
        tier = "UNKNOWN"
        if ledger_info: tier = ledger_info["tier"]
        elif backend_info: tier = backend_info["inferred_tier"] + " (Inferred)"
        
        inventory["endpoints"][path] = {
            "tier": tier,
            "status": status,
            "backend_defined": backend_info is not None,
            "canon_defined": ledger_info is not None,
            "used_in": list(set(usages))
        }
        
    with open(f"{OUTPUT_DIR}/command_center_inventory.json", "w") as f: json.dump(inventory, f, indent=2)
    
    # Markdown Report
    with open(f"{OUTPUT_DIR}/command_center_inventory.md", "w") as f:
        f.write("# D60.1 COMMAND CENTER INVENTORY (TRUTH MAP)\n")
        f.write(f"- **Unique Endpoints Used:** {len(unique_paths)}\n")
        f.write(f"- **Surfaces Scanned:** {len(surfaces)}\n")
        f.write(f"- **Ghosts:** {len(inventory['verification']['ghosts'])}\n")
        f.write(f"- **Unclassified:** {len(inventory['verification']['unclassified'])}\n\n")
        
        f.write("## Endpoint Usage Map\n")
        f.write("| Endpoint | Tier | Status | Used In (Sample) |\n")
        f.write("| :--- | :--- | :--- | :--- |\n")
        
        sorted_eps = sorted(inventory["endpoints"].items())
        for path, info in sorted_eps:
             usage_str = ", ".join([os.path.basename(u) for u in info["used_in"][:3]])
             if len(info["used_in"]) > 3: usage_str += ", ..."
             f.write(f"| `{path}` | **{info['tier']}** | {info['status']} | `{usage_str}` |\n")
             
    print("Inventory Gen Complete.")
    if inventory["verification"]["ghosts"]:
        print(f"WARNING: Ghosts found: {inventory['verification']['ghosts']}")
    if inventory["verification"]["unclassified"]:
        print(f"WARNING: Unclassified routes: {inventory['verification']['unclassified']}")

if __name__ == "__main__":
    generate_inventory()
