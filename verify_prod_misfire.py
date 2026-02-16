
import json

try:
    with open('system_state.json', 'r') as f:
        data = json.load(f)
    print(f"Top Level Keys: {list(data.keys())}")
    
    # Try the user suggested path: ops -> OS.Ops.Misfire
    if 'ops' in data:
         misfire = data['ops'].get('OS.Ops.Misfire', {})
    else:
         # Fallback to flattening or modules if present, debug
         misfire = {}
    
    if not misfire and 'modules' in data:
         misfire = data['modules'].get('OS.Ops.Misfire', {})

    if not misfire:
         print("FAILURE: Could not locate OS.Ops.Misfire")
         exit(1)
    print(f"Status: {misfire.get('status')}")
    print(f"Reason: {misfire.get('reason')}")
    meta = misfire.get('meta', {})
    diagnostics = meta.get('diagnostics')
    
    if diagnostics:
        print("--- DIAGNOSTICS EMBEDDED ---")
        print(json.dumps(diagnostics, indent=2))
    else:
        print("FAILURE: No Diagnostics found in meta.")
        print(f"Meta Keys: {list(meta.keys())}")

except FileNotFoundError:
    print("FAILURE: system_state.json not found.")
except Exception as e:
    print(f"FAILURE: {e}")
