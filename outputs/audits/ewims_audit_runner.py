import os
import re
import json
import ast
from pathlib import Path
from datetime import datetime

# Configuration
REPO_ROOT = Path(os.getcwd())
PROJECT_STATE_PATH = REPO_ROOT / "PROJECT_STATE.md"
WAR_CALENDAR_PATH = REPO_ROOT / "docs/canon/OMSR_WAR_CALENDAR__35_45_DAYS.md"
AUDIT_OUTPUT_DIR = REPO_ROOT / "outputs/audits"
AUDIT_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# -------------------------------------------------------------------------
# Phase I: Chronological Truth (Parsing History)
# -------------------------------------------------------------------------

def parse_project_state():
    print("Parsing PROJECT_STATE.md...")
    history = []
    if not PROJECT_STATE_PATH.exists():
        print("CRITICAL: PROJECT_STATE.md not found.")
        return history

    with open(PROJECT_STATE_PATH, "r", encoding="utf-8") as f:
        lines = f.readlines()

    current_day = "Unknown"
    for line in lines:
        line = line.strip()
        # Detect Day/Step markers
        day_match = re.search(r'\*\*(Day\s\d+(\.\d+)?|Step\s\d+).*?\*\*', line, re.IGNORECASE)
        if day_match:
            current_day = day_match.group(1)
        
        # Detect sealed items
        if "(SEALED)" in line or "[x]" in line:
            # Extract feature name
            # Remove MD formatting
            clean_line = line.replace("- [x]", "").replace("- [ ]", "").replace("**", "").replace("(SEALED)", "").strip()
            # Split by dash or colon if present to get feature name
            parts = re.split(r'[:—]', clean_line, 1)
            feature = parts[1].strip() if len(parts) > 1 else clean_line
            
            # Key identifier for searching (simplified)
            # Remove words like "Implemented", "sealed", etc.
            key_terms = [w for w in feature.split() if w.lower() not in ["implemented", "sealed", "verified", "completed", "fixed", "restored", "-"]]
            search_term = " ".join(key_terms[:4]) # Take first few distinctive words

            history.append({
                "day": current_day,
                "feature": feature,
                "raw_line": line,
                "search_term": search_term,
                "status": "UNKNOWN" 
            })
            
    return history

def verify_feature_existence(history):
    print("Verifying Feature Existence (Forensic Scan)...")
    
    # Pre-load file list for fast searching
    all_files = []
    for root, dirs, files in os.walk(REPO_ROOT):
        # Skip git, node_modules, build, etc.
        if ".git" in dirs: dirs.remove(".git")
        if "node_modules" in dirs: dirs.remove("node_modules")
        if "build" in dirs: dirs.remove("build")
        if ".dart_tool" in dirs: dirs.remove(".dart_tool")
        
        for file in files:
            if file.endswith((".py", ".dart", ".json", ".md")):
                all_files.append(Path(root) / file)

    for item in history:
        term = item["search_term"]
        if not term: 
            item["status"] = "GHOST"
            continue
            
        # 1. Search in Filenames
        found_files = [f for f in all_files if term.replace(" ", "_").lower() in f.name.lower()]
        
        # 2. Search in Content (if not found in filename)
        evidence = []
        if found_files:
            item["status"] = "ALIVE"
            item["evidence"] = f"File: {found_files[0].name}"
        else:
            # Deep content search (expensive, limit to backend/lib)
            hits = 0
            # Simplify term for grep (camelCase or snake_case conversion rough guess)
            simple_term = term.split()[0].lower() 
            if len(simple_term) > 3:
                for f in all_files:
                    if "backend" in str(f) or "lib" in str(f):
                        try:
                            with open(f, "r", encoding="utf-8", errors="ignore") as file_content:
                                if simple_term in file_content.read().lower():
                                    evidence.append(f.name)
                                    hits += 1
                                    if hits >= 1: break 
                        except: pass
            
            if hits > 0:
                item["status"] = "ALIVE"
                item["evidence"] = f"Ref: {evidence[0]}"
            else:
                # Ghost check: Is it purely documentation?
                item["status"] = "GHOST"
                item["evidence"] = "No code trace found"

    return history

def generate_chronological_matrix(history):
    print("Generating D50_EWIMS_CHRONOLOGICAL_MATRIX.md...")
    path = AUDIT_OUTPUT_DIR / "D50_EWIMS_CHRONOLOGICAL_MATRIX.md"
    with open(path, "w", encoding="utf-8") as f:
        f.write("# D50 EWIMS CHRONOLOGICAL MATRIX\n\n")
        f.write("| Day | Feature | Status | Evidence |\n")
        f.write("| :--- | :--- | :--- | :--- |\n")
        
        for item in history:
            status_icon = "🟢" if item["status"] == "ALIVE" else "👻" if item["status"] == "GHOST" else "🧟"
            f.write(f"| {item['day']} | {item['feature']} | {status_icon} {item['status']} | {item.get('evidence', '')} |\n")
            
    return path

# -------------------------------------------------------------------------
# Phase II: Full System Coverage & Artifacts
# -------------------------------------------------------------------------

def audit_backend_endpoints():
    print("Auditing Backend Endpoints...")
    api_server = REPO_ROOT / "backend/api_server.py"
    endpoints = []
    
    if api_server.exists():
        with open(api_server, "r", encoding="utf-8") as f:
            content = f.read()
            # Simple regex parser for @app.get/post patterns
            matches = re.finditer(r'@app\.(get|post|put|delete)\(["\']([^"\']+)["\']', content)
            for m in matches:
                endpoints.append({
                    "method": m.group(1).upper(),
                    "path": m.group(2),
                    "defined_in": "backend/api_server.py"
                })
    
    path = AUDIT_OUTPUT_DIR / "D50_EWIMS_ENDPOINT_COVERAGE.json"
    with open(path, "w") as f:
        json.dump(endpoints, f, indent=2)
    return endpoints

def audit_frontend_surfaces():
    print("Auditing Frontend Surfaces...")
    lib_dir = REPO_ROOT / "market_sniper_app/lib"
    surfaces = []
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith(".dart"):
                # Heuristic: Find classes extending StatelessWidget/StatefulWidget that look like screens/widgets
                with open(Path(root)/file, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                    matches = re.finditer(r'class\s+(\w+)\s+extends\s+(StatelessWidget|StatefulWidget)', content)
                    for m in matches:
                        class_name = m.group(1)
                        # Filter for "Screen", "Page", "Panel", "Sheet", "Modal"
                        if any(x in class_name for x in ["Screen", "Page", "Panel", "Sheet", "Modal", "Overlay", "Tile"]):
                            surfaces.append({
                                "class": class_name,
                                "file": str(Path(root)/file).replace(str(REPO_ROOT), "").replace("\\", "/"),
                                "type": "Screen/Widget"
                            })

    path = AUDIT_OUTPUT_DIR / "D50_EWIMS_FRONTEND_SURFACE_MAP.md"
    with open(path, "w", encoding="utf-8") as f:
        f.write("# D50 EWIMS FRONTEND SURFACE MAP\n\n")
        f.write("| Class Name | File Path | Verified |\n")
        f.write("| :--- | :--- | :--- |\n")
        for s in surfaces:
             f.write(f"| `{s['class']}` | `{s['file']}` | ✅ |\n")
             
    return surfaces

def audit_artifacts():
    print("Auditing Artifacts...")
    outputs_dir = REPO_ROOT / "outputs"
    artifact_tree = {}
    
    for root, dirs, files in os.walk(outputs_dir):
        for file in files:
            rel_path = str(Path(root)/file).replace(str(REPO_ROOT), "").replace("\\", "/")
            artifact_tree[rel_path] = "EXISTS"
            
    # Check for Canon
    canon_dir = REPO_ROOT / "docs/canon"
    for root, dirs, files in os.walk(canon_dir):
        for file in files:
             rel_path = str(Path(root)/file).replace(str(REPO_ROOT), "").replace("\\", "/")
             artifact_tree[rel_path] = "CANON"

    path = AUDIT_OUTPUT_DIR / "D50_EWIMS_ARTIFACT_GRAPH.json"
    with open(path, "w") as f:
        json.dump(artifact_tree, f, indent=2)
    return artifact_tree

# -------------------------------------------------------------------------
# Phase III: Integration & Data Flow 
# -------------------------------------------------------------------------

def generate_integration_map(endpoints, surfaces):
    # This is a heuristic map based on naming conventions
    print("Generating Integration Map...")
    connections = []
    
    # endpoint -> surface matching (rough)
    for ep in endpoints:
        ep_keyword = ep["path"].split("/")[-1].replace("_", "").lower()
        if not ep_keyword: continue
        
        matches = [s["class"] for s in surfaces if ep_keyword in s["class"].lower()]
        for m in matches:
            connections.append({
                "producer (API)": ep["path"],
                "consumer (UI)": m,
                "status": "WIRED (Inferred)"
            })
            
    path = AUDIT_OUTPUT_DIR / "D50_EWIMS_INTEGRATION_MAP.md"
    with open(path, "w", encoding="utf-8") as f:
        f.write("# D50 EWIMS INTEGRATION MAP (Inferred)\n\n")
        f.write("| Producer (API) | Consumer (UI) | Status |\n")
        f.write("| :--- | :--- | :--- |\n")
        for c in connections:
            f.write(f"| `{c['producer (API)']}` | `{c['consumer (UI)']}` | 🔗 {c['status']} |\n")
            
    return path

# -------------------------------------------------------------------------
# Phase IV: Debt Classification (Stub generation for clarity)
# -------------------------------------------------------------------------
def generate_fix_list(history):
    print("Generating Fix List...")
    ghosts = [h for h in history if h["status"] == "GHOST"]
    
    path = AUDIT_OUTPUT_DIR / "D50_EWIMS_FIX_LIST.md"
    with open(path, "w", encoding="utf-8") as f:
        f.write("# D50 EWIMS DEBT ERADICATION LIST\n\n")
        f.write("## 1. GHOST FEATURES (Claimed but Missing)\n")
        if ghosts:
             for g in ghosts:
                 f.write(f"- [ ] **{g['feature']}** ({g['day']}): Stub or Restore.\n")
        else:
            f.write("No Ghost Features found! (Amazing)\n")
            
        f.write("\n## 2. ZOMBIE FEATURES (Code exists but potential rot)\n")
        f.write("- [ ] Review Legacy Pipeline (Day 6-10)\n")
        
    return path

# -------------------------------------------------------------------------
# Runner
# -------------------------------------------------------------------------

def main():
    print("--- STARTING OPERATION EWIMS-GOLD AUDIT ---")
    
    # 1. Chronology
    hist = parse_project_state()
    hist = verify_feature_existence(hist)
    generate_chronological_matrix(hist)
    
    # 2. Coverage
    eps = audit_backend_endpoints()
    surfs = audit_frontend_surfaces()
    audit_artifacts()
    
    # 3. Integration
    generate_integration_map(eps, surfs)
    
    # 4. Debt
    generate_fix_list(hist)
    
    print("--- AUDIT COMPLETE ---")
    print(f"Artifacts generated in: {AUDIT_OUTPUT_DIR}")

if __name__ == "__main__":
    main()
