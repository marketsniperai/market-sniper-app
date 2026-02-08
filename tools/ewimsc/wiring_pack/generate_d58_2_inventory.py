import os
import sys
import json
import inspect
import ast
from pathlib import Path
from datetime import datetime

# Add repo root to sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

# Configuration
TRIAGE_REPORT_PATH = REPO_ROOT / "outputs/proofs/D57_5_ZOMBIE_TRIAGE/zombie_report.json"
OUTPUT_DIR = REPO_ROOT / "outputs/proofs/D58_2_UNKNOWN_INVENTORY"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

class HandlerVisitor(ast.NodeVisitor):
    def __init__(self):
        self.reads = set()
        self.writes = set()
        self.deps = set()
        self.has_compute = False
        self.has_cost = False

    def visit_Call(self, node):
        # Check for open()
        if isinstance(node.func, ast.Name) and node.func.id == 'open':
            # Try to get file path if it's a string literal
            if node.args and isinstance(node.args[0], ast.Constant):
                path = str(node.args[0].value)
                mode = 'r'
                if len(node.args) > 1 and isinstance(node.args[1], ast.Constant):
                    mode = node.args[1].value
                
                # Check keywords for mode
                for kw in node.keywords:
                    if kw.arg == 'mode' and isinstance(kw.value, ast.Constant):
                        mode = kw.value.value
                
                if 'w' in mode or 'a' in mode or '+' in mode:
                    self.writes.add(path)
                else:
                    self.reads.add(path)
        
        # Check for json.load/dump
        if isinstance(node.func, ast.Attribute):
            if isinstance(node.func.value, ast.Name) and node.func.value.id == 'json':
                if node.func.attr == 'dump':
                    self.writes.add("JSON_WRITE")
                elif node.func.attr == 'load':
                    self.reads.add("JSON_READ")

        # Check for cost triggers
        func_name = ""
        if isinstance(node.func, ast.Attribute):
            func_name = node.func.attr
        elif isinstance(node.func, ast.Name):
            func_name = node.func.id
            
        if "openai" in func_name.lower() or "gemini" in func_name.lower() or "polygon" in func_name.lower():
            self.has_cost = True
            self.deps.add(func_name)
            
        self.generic_visit(node)

    def visit_Import(self, node):
        for name in node.names:
            if "openai" in name.name or "polygon" in name.name:
                self.has_cost = True
                self.deps.add(name.name)
        self.generic_visit(node)

    def visit_ImportFrom(self, node):
        if node.module and ("openai" in node.module or "polygon" in node.module):
            self.has_cost = True
            self.deps.add(node.module)
        self.generic_visit(node)

def analyze_handler(func):
    try:
        source = inspect.getsource(func)
        tree = ast.parse(source)
        visitor = HandlerVisitor()
        visitor.visit(tree)
        
        behavior = "MIXED/UNKNOWN"
        if visitor.has_cost:
            behavior = "COST_TRIGGER"
        elif visitor.writes:
            behavior = "WRITE_STATE"
        elif visitor.reads:
            behavior = "READ_ARTIFACT"
        elif visitor.has_compute: # Placeholder, need logic
            behavior = "COMPUTE_ON_DEMAND"
        
        # Default fallback for simple reads
        if behavior == "MIXED/UNKNOWN" and "return" in source:
             behavior = "COMPUTE_ON_DEMAND" # Just returns something

        return {
            "handler_file": inspect.getfile(func).replace(str(REPO_ROOT), "").lstrip("\\/"),
            "handler_name": func.__name__,
            "behavior_type": behavior,
            "reads_artifacts": list(visitor.reads),
            "writes_artifacts": list(visitor.writes),
            "external_deps": list(visitor.deps)
        }
    except Exception as e:
        return {
            "error": str(e),
            "behavior_type": "ANALYSIS_FAILED"
        }

def main():
    print("--- D58.2 IDENTIFY UNKNOWN INVENTORY ---")
    
    # 1. Load Triage
    if not TRIAGE_REPORT_PATH.exists():
        print(f"FATAL: Triage report missing at {TRIAGE_REPORT_PATH}")
        sys.exit(1)
        
    triage_data = json.loads(TRIAGE_REPORT_PATH.read_text(encoding="utf-8"))
    zombies = [r for r in triage_data.get("routes", []) if r["status"] == "UNKNOWN_ZOMBIE"]
    print(f"Analyzing {len(zombies)} UNKNOWN_ZOMBIE routes...")
    
    # 2. Load App
    try:
        from backend.api_server import app
        from fastapi.routing import APIRoute
        print("Backend loaded.")
    except Exception as e:
        print(f"FATAL: Backend import failed: {e}")
        sys.exit(1)
        
    # Map normalized path to APIRoute
    route_map = {}
    for r in app.routes:
        if isinstance(r, APIRoute):
            route_map[r.path] = r
            
    # 3. Analyze
    inventory = []
    
    for z in zombies:
        path = z["normalized_path"]
        route = route_map.get(path)
        
        item = {
            "normalized_path": path,
            "methods": z["methods"],
            "suggestion": z.get("expected_public_status", "review")
        }
        
        if route:
            analysis = analyze_handler(route.endpoint)
            item.update(analysis)
            
            # Refine Suggestion based on behavior
            if item["behavior_type"] == "READ_ARTIFACT" and "risk_class" not in item:
                 item["suggested_destiny"] = "PUBLIC_PRODUCT"
            elif item["behavior_type"] in ["WRITE_STATE", "COST_TRIGGER"]:
                 item["suggested_destiny"] = "LAB_INTERNAL"
            else:
                 item["suggested_destiny"] = "LAB_INTERNAL" # Default safe
                 
        else:
            item["error"] = "Route not found in App (Router mounting issue?)"
            item["suggested_destiny"] = "REMOVE"
            
        inventory.append(item)
        
    # 4. Outputs
    
    # JSON
    json_out = OUTPUT_DIR / "unknown_inventory.json"
    json_out.write_text(json.dumps(inventory, indent=2), encoding="utf-8")
    print(f"Saved Inventory to {json_out}")
    
    # Markdown
    md_lines = [
        "| Path | Handler | Behavior | Reads | Writes | Destiny |",
        "|---|---|---|---|---|---|"
    ]
    
    for i in inventory:
        handler = i.get("handler_name", "N/A")
        beh = i.get("behavior_type", "UNKNOWN")
        reads = "<br>".join(i.get("reads_artifacts", [])) or "-"
        writes = "<br>".join(i.get("writes_artifacts", [])) or "-"
        dest = i.get("suggested_destiny", "REVIEW")
        
        md_lines.append(f"| `{i['normalized_path']}` | `{handler}` | {beh} | {reads} | {writes} | **{dest}** |")
        
    md_out = OUTPUT_DIR / "unknown_inventory.md"
    md_out.write_text("\n".join(md_lines), encoding="utf-8")
    print(f"Saved Markdown to {md_out}")
    
    print("SUCCESS")

if __name__ == "__main__":
    main()
