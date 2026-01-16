import json
import os
import re
from typing import Dict, List, Any

REGISTRY_PATH = "os_registry.json"
API_SERVER_PATH = "backend/api_server.py"

class ModuleRegistryEnforcer:
    def __init__(self):
        self.registry = self.load_registry()
        self.errors = []
        
    def load_registry(self):
        if not os.path.exists(REGISTRY_PATH):
            raise FileNotFoundError(f"{REGISTRY_PATH} not found")
        with open(REGISTRY_PATH, "r") as f:
            return json.load(f)
            
    def check(self) -> Dict[str, Any]:
        modules = self.registry.get("modules", [])
        
        # 1. Validate Schema & Files
        for m in modules:
            mid = m.get("module_id")
            if not mid:
                self.errors.append("Validation: Module missing module_id")
                continue
            
            # primary_files existence
            for fpath in m.get("primary_files", []):
                # normalize path
                np = fpath.replace("/", os.sep).replace("\\", os.sep)
                if not os.path.exists(np):
                    self.errors.append(f"Module {mid}: Primary file not found: {fpath}")
                    
        # 2. Validate Ports (Endpoints)
        # Scan api_server.py for @app.get/post/etc("ROUTE")
        api_content = ""
        if os.path.exists(API_SERVER_PATH):
            with open(API_SERVER_PATH, "r", encoding="utf-8") as f:
                api_content = f.read()
        
        for m in modules:
            mid = m.get("module_id")
            ports = m.get("wiring", {}).get("ports", [])
            for p in ports:
                 # Check if HTTP endpoint
                 if p.startswith("GET ") or p.startswith("POST ") or p.startswith("PUT ") or p.startswith("DELETE "):
                     method, route = p.split(" ", 1)
                     # Search for exact route string in api_server content
                     # simplistic check: look for '"/route"' or "'/route'"
                     # also handle parameters like /lab/run_pipeline
                     # We verify it exists in code.
                     if f'"{route}"' not in api_content and f"'{route}'" not in api_content:
                         # Try simple warning if it's dynamic
                         self.errors.append(f"Module {mid}: Port {p} not found in {API_SERVER_PATH}")
                         
        # 3. Validate Wiring Edges (Deps)
        all_ids = set(m["module_id"] for m in modules)
        for m in modules:
            mid = m.get("module_id")
            deps = m.get("wiring", {}).get("dependencies", {})
            
            for d in deps.get("upstream", []):
                if d != "*" and d not in all_ids:
                    self.errors.append(f"Module {mid}: Unknown upstream dependency '{d}'")
            
            for d in deps.get("downstream", []):
                if d != "*" and d not in all_ids:
                     self.errors.append(f"Module {mid}: Unknown downstream dependency '{d}'")

        status = "PASS" if not self.errors else "FAIL"
        return {
            "status": status,
            "errors": self.errors,
            "module_count": len(modules)
        }

if __name__ == "__main__":
    enforcer = ModuleRegistryEnforcer()
    res = enforcer.check()
    print(json.dumps(res, indent=2))
