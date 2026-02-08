import os
import sys
import json
import re
from pathlib import Path
from datetime import datetime

# Add repo root to sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

# Configuration
TRIAGE_REPORT_PATH = REPO_ROOT / "outputs/proofs/D57_5_ZOMBIE_TRIAGE/zombie_report.json"
OUTPUT_DIR = REPO_ROOT / "outputs/proofs/D57_7_WIRING_PACK"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def get_prod_urls():
    """Grep for production URLs in the codebase."""
    found_urls = set()
    url_pattern = re.compile(r"https://marketsniper-api[a-zA-Z0-9\.\-]+")
    
    scan_dirs = ["lib", "backend", "tools"]
    for d in scan_dirs:
        root_path = REPO_ROOT / d
        if not root_path.exists(): continue
        
        for root, _, files in os.walk(root_path):
            for file in files:
                if file.endswith((".dart", ".py", ".md", ".json", ".ps1", ".sh")):
                    try:
                        content = (Path(root) / file).read_text(encoding="utf-8", errors="ignore")
                        matches = url_pattern.findall(content)
                        for m in matches:
                            found_urls.add(m)
                    except Exception:
                        pass
    return sorted(list(found_urls))

def get_artifact_wiring():
    """Grep for artifact roots and buckets."""
    wiring = {
        "buckets": set(),
        "artifact_roots": set(),
        "files": set()
    }
    
    bucket_pattern = re.compile(r"gs://[a-zA-Z0-9\.\-_]+")
    # specific interesting files
    interesting_files = ["dashboard_market_sniper.json", "run_manifest.json"]
    
    scan_dirs = ["backend", "tools"]
    for d in scan_dirs:
        root_path = REPO_ROOT / d
        if not root_path.exists(): continue
        
        for root, _, files in os.walk(root_path):
            for file in files:
                if file.endswith((".py", ".json", ".ps1", ".sh")):
                    try:
                        content = (Path(root) / file).read_text(encoding="utf-8", errors="ignore")
                        
                        # Buckets
                        matches = bucket_pattern.findall(content)
                        for m in matches:
                            wiring["buckets"].add(m)
                            
                        # Artifact Roots (heuristic)
                        if "outputs/" in content:
                             wiring["artifact_roots"].add("outputs/")
                             
                        # Files
                        for f in interesting_files:
                            if f in content:
                                wiring["files"].add(f)
                                
                    except Exception:
                        pass
                        
    return {k: sorted(list(v)) for k, v in wiring.items()}

def get_pipeline_wiring():
    """Grep for pipeline markers."""
    wiring = {
        "schedulers": set(),
        "jobs": set(), 
        "entrypoints": set()
    }
    
    scan_dirs = ["backend", "tools", ".github"]
    for d in scan_dirs:
        root_path = REPO_ROOT / d
        if not root_path.exists(): continue
        
        for root, _, files in os.walk(root_path):
            for file in files:
                # Look for yaml, py, ps1
                if file.endswith((".yml", ".yaml", ".py", ".ps1")):
                    try:
                        content = (Path(root) / file).read_text(encoding="utf-8", errors="ignore")
                        
                        if "Cloud Scheduler" in content or "schedule" in content and ".yml" in file:
                            wiring["schedulers"].add(file)
                            
                        if "run_pipeline" in content:
                            wiring["jobs"].add("run_pipeline")
                        if "pipeline_light" in content:
                            wiring["jobs"].add("pipeline_light")
                        
                        if file in ["main.py", "pipeline.py"]:
                             wiring["entrypoints"].add(file)

                    except Exception:
                        pass
    return {k: sorted(list(v)) for k, v in wiring.items()}


def get_routes(app):
    """Extract routes from FastAPI app."""
    routes = []
    for route in app.routes:
        if hasattr(route, "path") and hasattr(route, "methods"):
            routes.append({
                "path": route.path,
                "methods": sorted(list(route.methods)),
                "name": route.name
            })
    return sorted(routes, key=lambda x: x["path"])

def load_triage_data():
    if TRIAGE_REPORT_PATH.exists():
        try:
            return json.loads(TRIAGE_REPORT_PATH.read_text(encoding="utf-8"))
        except:
            return None
    return None

def main():
    print("--- WIRING PACK GENERATOR ---")
    
    # 1. Import App & Routes
    try:
        from backend.api_server import app
        print("Imported backend.api_server:app successfully.")
        routes = get_routes(app)
        print(f"Discovered {len(routes)} routes.")
    except Exception as e:
        print(f"FATAL: Could not import backend.api_server: {e}")
        sys.exit(1)
        
    # 2. Triage Data
    triage_data = load_triage_data()
    triage_map = {}
    if triage_data:
        print("Loaded Triage Report.")
        for r in triage_data.get("routes", []):
            triage_map[r["normalized_path"]] = r.get("status", "UNKNOWN")
    else:
        print("WARNING: No Triage Report found. Status will be inferred or UNKNOWN.")
        
    # 3. Merge Route Data
    final_routes = []
    for r in routes:
        path = r["path"]
        status = triage_map.get(path, "UNKNOWN_ZOMBIE") # Default to ZOMBIE if not in Triage
        
        # Simple heuristic fallback if triage missing
        if status == "UNKNOWN_ZOMBIE":
            if path.startswith("/lab/"): status = "LAB_INTERNAL"
            elif path.startswith("/docs") or path == "/openapi.json": status = "PUBLIC_DOCS"
        
        final_routes.append({
            "path": path,
            "methods": r["methods"],
            "status": status
        })
        
    # 4. Wiring Discovery
    prod_urls = get_prod_urls()
    artifact_wiring = get_artifact_wiring()
    pipeline_wiring = get_pipeline_wiring()
    
    local_port = os.environ.get("PORT", "8787")
    
    # 5. Assemble Bundle
    bundle = {
        "meta": {
            "generated_at": datetime.now().isoformat(),
            "generator": "D57.7 Wiring Pack Generator"
        },
        "base_urls": {
            "local": f"http://127.0.0.1:{local_port}",
            "prod_discovered": prod_urls
        },
        "routes": final_routes,
        "artifact_wiring": artifact_wiring,
        "pipeline_wiring": pipeline_wiring
    }
    
    # 6. Write Outputs
    
    # JSON
    json_path = OUTPUT_DIR / "WIRING_PACK.json"
    json_path.write_text(json.dumps(bundle, indent=2), encoding="utf-8")
    print(f"Wrote {json_path}")
    
    # MD
    md_lines = [
        "# MARKET SNIPER OS - FULL WIRING PACK",
        f"**Generated:** {bundle['meta']['generated_at']}",
        "",
        "## 1. Base URLs",
        f"- **Local:** `{bundle['base_urls']['local']}`",
        "- **Prod (Discovered):**"
    ]
    for u in prod_urls:
        md_lines.append(f"  - `{u}`")
        
    md_lines.append("")
    md_lines.append("## 2. Inventory & Classification")
    md_lines.append("| Status | Method | Path |")
    md_lines.append("|---|---|---|")
    
    # Group by status for readability
    for status in sorted(list(set(r["status"] for r in final_routes))):
        for r in final_routes:
            if r["status"] == status:
                methods = ",".join(r["methods"])
                md_lines.append(f"| **{status}** | {methods} | `{r['path']}` |")
                
    md_lines.append("")
    md_lines.append("## 3. Data Wiring")
    md_lines.append("### Buckets")
    for b in artifact_wiring["buckets"]: md_lines.append(f"- `{b}`")
    md_lines.append("### Artifact Roots")
    for r in artifact_wiring["artifact_roots"]: md_lines.append(f"- `{r}`")
    md_lines.append("### Critical Files")
    for f in artifact_wiring["files"]: md_lines.append(f"- `{f}`")
    
    md_lines.append("")
    md_lines.append("## 4. Pipeline Wiring")
    md_lines.append("### Jobs")
    for j in pipeline_wiring["jobs"]: md_lines.append(f"- `{j}`")
    md_lines.append("### Entrypoints")
    for e in pipeline_wiring["entrypoints"]: md_lines.append(f"- `{e}`")
    md_lines.append("### Schedulers")
    for s in pipeline_wiring["schedulers"]: md_lines.append(f"- `{s}`")
    
    md_path = OUTPUT_DIR / "WIRING_PACK.md"
    md_path.write_text("\n".join(md_lines), encoding="utf-8")
    print(f"Wrote {md_path}")
    
    # TEXT (NotebookLM Optimized - minimal formatting, high density)
    txt_lines = [
        "MARKET SNIPER OS COMPREHENSIVE WIRING MAP",
        "USE THIS TO UNDERSTAND SYSTEM CONNECTIVITY.",
        "",
        "SECTION: BASE URLS",
        f"LOCAL: {bundle['base_urls']['local']}",
        "PROD CANDIDATES: " + ", ".join(prod_urls),
        "",
        "SECTION: ENDPOINT INVENTORY (STATUS METHOD PATH)",
    ]
    for r in final_routes:
         txt_lines.append(f"[{r['status']}] {','.join(r['methods'])} {r['path']}")
         
    txt_lines.append("")
    txt_lines.append("SECTION: DATA ARTIFACTS")
    txt_lines.append("BUCKETS: " + ", ".join(artifact_wiring["buckets"]))
    txt_lines.append("ROOTS: " + ", ".join(artifact_wiring["artifact_roots"]))
    txt_lines.append("FILES: " + ", ".join(artifact_wiring["files"]))
    
    txt_lines.append("")
    txt_lines.append("SECTION: PIPELINES")
    txt_lines.append("JOBS: " + ", ".join(pipeline_wiring["jobs"]))
    txt_lines.append("SCHEDULERS: " + ", ".join(pipeline_wiring["schedulers"]))
    
    txt_path = OUTPUT_DIR / "WIRING_PACK_NOTEBOOKLM.txt"
    txt_path.write_text("\n".join(txt_lines), encoding="utf-8")
    print(f"Wrote {txt_path}")
    
    print("\nSUCCESS: Wiring Pack Generated.")

if __name__ == "__main__":
    main()
