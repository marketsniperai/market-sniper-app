import json
import os
import sys
from module_registry_enforcer import ModuleRegistryEnforcer

OUTPUT_FILE = "outputs/runtime/day_27/day_27_registry_enforcement_report.json"

def main():
    print("Running Day 27 Registry Enforcer...")
    enforcer = ModuleRegistryEnforcer()
    result = enforcer.check()
    
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w") as f:
        json.dump(result, f, indent=2)
        
    print(json.dumps(result, indent=2))
    
    if result["status"] != "PASS":
        print("VERIFICATION FAILED")
        sys.exit(1)
    else:
        print("VERIFICATION PASSED")
        sys.exit(0)

if __name__ == "__main__":
    main()
