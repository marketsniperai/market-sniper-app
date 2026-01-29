
import json
import os

REGISTRY_PATH = "os_registry.json"

def fix_registry():
    print(f"Fixing paths in {REGISTRY_PATH}...")
    
    if not os.path.exists(REGISTRY_PATH):
        print("Registry not found")
        return

    with open(REGISTRY_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    count = 0
    for m in data.get("modules", []):
        new_files = []
        for fpath in m.get("primary_files", []):
            if not fpath.startswith("/"):
                fpath = "/" + fpath
                count += 1
            new_files.append(fpath)
        m["primary_files"] = new_files
        
    with open(REGISTRY_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)
        
    print(f"Fixed {count} paths.")

if __name__ == "__main__":
    fix_registry()
