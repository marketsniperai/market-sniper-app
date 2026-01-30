
import os
import json
import re
from datetime import datetime

# Paths
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REGISTRY_PATH = os.path.join(REPO_ROOT, "os_registry.json")
CANON_PATH = os.path.join(REPO_ROOT, "docs", "canon", "OS_MODULES.md")
OUTPUT_DIR = os.path.join(REPO_ROOT, "outputs", "os")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "os_knowledge_index.json")

# Ensure output dir
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

def load_registry():
    if not os.path.exists(REGISTRY_PATH):
        print(f"ERROR: Registry not found at {REGISTRY_PATH}")
        return []
    try:
        with open(REGISTRY_PATH, 'r') as f:
            data = json.load(f)
            return data.get("modules", [])
    except Exception as e:
        print(f"ERROR: Failed to load registry: {e}")
        return []

def extract_descriptions_from_canon():
    descriptions = {}
    if not os.path.exists(CANON_PATH):
        print(f"WARNING: Canon not found at {CANON_PATH}")
        return descriptions
    
    try:
        with open(CANON_PATH, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            for line in lines:
                # Capture table rows: | **ID** | Name | Type | Description | ...
                match = re.search(r'\|\s*\*\*(OS\.[^\|]+)\*\*\s*\|\s*([^\|]+)\s*\|\s*([^\|]+)\s*\|\s*([^\|]+)\s*\|', line)
                if match:
                    mod_id = match.group(1).strip()
                    desc = match.group(4).strip()
                    descriptions[mod_id] = desc
    except Exception as e:
        print(f"WARNING: Failed to parse canon: {e}")
    
    return descriptions

def generate_index():
    print("Generating OS Knowledge Index...")
    
    registry_modules = load_registry()
    canon_descriptions = extract_descriptions_from_canon()
    
    modules = []
    
    # Process Modules from Registry
    for mod in registry_modules:
        mid = mod.get("module_id")
        name = mod.get("name")
        why = canon_descriptions.get(mid, f"Core functionality for {name}.")
        
        # Determine consumers from wiring
        consumers = mod.get("wiring", {}).get("dependencies", {}).get("downstream", [])
        if consumers == ["*"]:
            consumers = ["ALL"]

        modules.append({
            "id": mid,
            "name": name,
            "paths": mod.get("primary_files", []),
            "why": why,
            "consumers": consumers
        })

    # Static/Inferred Surfaces (v1)
    surfaces = [
        {
            "id": "Surface.Dashboard",
            "name": "Mission Dashboard",
            "paths": ["lib/screens/dashboard_screen.dart"],
            "why": "Primary tactical interface for market status and signals.",
            "consumers": ["User"]
        },
        {
            "id": "Surface.OnDemand",
            "name": "On-Demand Intelligence",
            "paths": ["lib/screens/on_demand_panel.dart", "lib/adapters/on_demand/"],
            "why": "Ad-hoc analysis of any ticker against institutional levels.",
            "consumers": ["User"]
        },
        {
            "id": "Surface.Elite",
            "name": "Elite Overlay",
            "paths": ["lib/widgets/elite_interaction_sheet.dart"],
            "why": "Contextual reasoning and system explainer interface.",
            "consumers": ["User", "Elite Logic"]
        },
        {
            "id": "Surface.WarRoom",
            "name": "War Room",
            "paths": ["lib/screens/war_room_screen.dart", "backend/os_ops/war_room.py"],
            "why": "Operational health monitoring and system diagnostics.",
            "consumers": ["Founder", "Ops"]
        }
    ]

    # Inferred Artifacts (v1 - Representative)
    artifacts = [
        {
            "name": "Project State",
            "path": "docs/canon/PROJECT_STATE.md",
            "producer": "Founder/Agent",
            "why": "High-level project tracking.",
            "pii_safe": True
        },
        {
            "name": "OS Registry",
            "path": "os_registry.json",
            "producer": "Founder/Agent",
            "why": "Canonical system architecture map.",
            "pii_safe": True
        },
        {
            "name": "War Calendar",
            "path": "docs/canon/OMSR_WAR_CALENDAR__35_45_DAYS.md",
            "producer": "Founder/Agent",
            "why": "Detailed execution schedule.",
            "pii_safe": True
        }
    ]

    # Lexicon Constraints (v1)
    lexicon_constraints = [
        {
            "surface_or_module": "Elite",
            "bans": ["Buy", "Sell", "Prediction", "Guarantee"],
            "safe_phrases": ["Context suggests...", "Levels indicating...", "Risk structure..."]
        },
        {
            "surface_or_module": "Dashboard",
            "bans": ["Loading...", "Error"],
            "safe_phrases": ["Calculating...", "Unavailable"]
        }
    ]

    index = {
        "metadata": {
            "generated_at_utc": datetime.utcnow().isoformat() + "Z",
            "version": "1.0",
            "generator": "generate_os_knowledge_index.py"
        },
        "modules": modules,
        "surfaces": surfaces,
        "artifacts": artifacts,
        "lexicon_constraints": lexicon_constraints
    }

    with open(OUTPUT_FILE, 'w') as f:
        json.dump(index, f, indent=4)
    
    print(f"SUCCESS: Index written to {OUTPUT_FILE}")
    print(f"Modules: {len(modules)}, Surfaces: {len(surfaces)}, Artifacts: {len(artifacts)}")

if __name__ == "__main__":
    generate_index()
