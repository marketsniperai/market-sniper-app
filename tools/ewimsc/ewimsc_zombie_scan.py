import sys
import os
import json
import re
from pathlib import Path
from datetime import datetime

# Setup paths to import backend
sys.path.append(os.getcwd())

# Force local env
os.environ["ENV"] = "local"
os.environ["PUBLIC_DOCS"] = "0"

try:
    from backend.api_server import app
    from fastapi.routing import APIRoute
except ImportError as e:
    print(f"FATAL: Could not import backend.api_server: {e}")
    sys.exit(1)

# Config
CANON_DIR = Path("docs/canon")
OUTPUT_DIR = Path("outputs/proofs/D57_5_ZOMBIE_TRIAGE") # New output dir for D57.5
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
ALLOWLIST_PATH = Path("tools/ewimsc/zombie_allowlist.json")

def load_allowlist():
    if ALLOWLIST_PATH.exists():
        with open(ALLOWLIST_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"known_aliases": {}, "known_public_routes": [], "internal_prefixes": []}

ALLOWLIST = load_allowlist()

def classify_route(path):
    # 1. Check Public
    if path in ALLOWLIST["known_public_routes"]:
        return "PUBLIC_PRODUCT", 200
        
    # 2. Check Alias
    if path in ALLOWLIST["known_aliases"]:
        return "DEPRECATED_ALIAS", "redirect" # Or whatever expected behavior
        
    # 3. Check Internal Prefixes
    for prefix in ALLOWLIST.get("internal_prefixes", []):
        if path.startswith(prefix):
            return "LAB_INTERNAL", 403
            
    # 4. Check Elite Prefixes
    for prefix in ALLOWLIST.get("elite_prefixes", []):
        if path.startswith(prefix):
            return "ELITE_GATED", 403
            
    # 5. Unknown
    return "UNKNOWN_ZOMBIE", "review"

def scan():
    print("--- EWIMSC ZOMBIE TRIAGE (FULL STEEL) ---")
    
    # Raw Collection
    raw_routes = []
    for route in app.routes:
        if isinstance(route, APIRoute):
            raw_routes.append({
                "path": route.path,
                "methods": sorted(list(route.methods)),
                "name": route.name
            })
            
    # Dedup & Normalize
    # Key: (normalized_path, sorted_methods_wo_head)
    dedup_map = {}
    
    for r in raw_routes:
        # Normalize
        norm_path = r["path"].rstrip("/")
        if norm_path == "": norm_path = "/"
        
        methods = set(r["methods"])
        if "HEAD" in methods: methods.remove("HEAD")
        methods_key = tuple(sorted(list(methods)))
        
        key = (norm_path, methods_key)
        
        if key not in dedup_map:
            status, exp_status = classify_route(norm_path)
            dedup_map[key] = {
                "normalized_path": norm_path,
                "methods": list(methods_key),
                "original_paths": set(),
                "endpoint_names": set(),
                "status": status,
                "expected_public_status": exp_status
            }
            
        dedup_map[key]["original_paths"].add(r["path"])
        dedup_map[key]["endpoint_names"].add(r["name"])
        
    # Convert to List
    final_routes = []
    for k, v in dedup_map.items():
        v["original_paths"] = sorted(list(v["original_paths"]))
        v["endpoint_names"] = sorted(list(v["endpoint_names"]))
        final_routes.append(v)
        
    final_routes.sort(key=lambda x: x["normalized_path"])
    
    # Stats
    stats = {
        "total_unique": len(final_routes),
        "core_public": len([r for r in final_routes if r["status"] == "PUBLIC_PRODUCT"]),
        "lab_internal": len([r for r in final_routes if r["status"] == "LAB_INTERNAL"]),
        "elite_gated": len([r for r in final_routes if r["status"] == "ELITE_GATED"]),
        "aliases": len([r for r in final_routes if r["status"] == "DEPRECATED_ALIAS"]),
        "unknown_zombies": len([r for r in final_routes if r["status"] == "UNKNOWN_ZOMBIE"])
    }
    
    # JSON Report
    report = {
        "timestamp": datetime.now().isoformat(),
        "stats": stats,
        "routes": final_routes
    }
    
    with open(OUTPUT_DIR / "zombie_report.json", "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
        
    # Markdown Ledger
    md_lines = [
        "# ZOMBIE LEDGER (TRIAGED)",
        f"> **Generated:** {datetime.now().isoformat()}",
        f"> **Unique Routes:** {stats['total_unique']}",
        f"> **Public/Product:** {stats['core_public']}",
        f"> **LAB/Internal:** {stats['lab_internal']}",
        f"> **Elite/Gated:** {stats['elite_gated']}",
        f"> **Aliases:** {stats['aliases']}",
        f"> **Unknown Zombies:** {stats['unknown_zombies']}",
        "",
        "| Class | Method | Path | Expect | Names |",
        "| :--- | :--- | :--- | :--- | :--- |"
    ]
    
    for r in final_routes:
        names = "<br>".join(r["endpoint_names"])
        methods = ", ".join(r["methods"])
        md_lines.append(f"| **{r['status']}** | `{methods}` | `{r['normalized_path']}` | `{r['expected_public_status']}` | `{names}` |")
        
    with open(CANON_DIR / "ZOMBIE_LEDGER.md", "w", encoding="utf-8") as f:
        f.write("\n".join(md_lines))
        
    print(f"Triage Complete.")
    print(f"Stats: {stats}")
    print(f"Report: {OUTPUT_DIR / 'zombie_report.json'}")
    print(f"Ledger: {CANON_DIR / 'ZOMBIE_LEDGER.md'}")

if __name__ == "__main__":
    scan()
