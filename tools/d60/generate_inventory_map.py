import json
import os
import sys

# Define Paths
BACKEND_JSON = "outputs/proofs/D60_1_COMMAND_CENTER/backend_surface.json"
FRONTEND_JSON = "outputs/proofs/D60_1_COMMAND_CENTER/frontend_surface.json"
OUTPUT_JSON = "outputs/proofs/D60_1_COMMAND_CENTER/command_center_inventory.json"
OUTPUT_MD = "outputs/proofs/D60_1_COMMAND_CENTER/command_center_inventory.md"
REPORT_JSON = "outputs/proofs/D60_1_COMMAND_CENTER/verification_report.json"

def main():
    print("Generating Command Center Inventory Map...")
    
    # Load Data
    with open(BACKEND_JSON, "r", encoding="utf-8") as f:
        backend_data = json.load(f)
        
    with open(FRONTEND_JSON, "r", encoding="utf-8") as f:
        frontend_data = json.load(f)
        
    # Build Backend LUT: Path -> [ {method, classification, name} ]
    backend_lut = {}
    for entry in backend_data:
        path = entry["path"]
        if path not in backend_lut:
            backend_lut[path] = []
        backend_lut[path].append(entry)
        
    # Process Frontend
    inventory = []
    validation_errors = []
    
    # Filter for CC Surfaces only? 
    # User said "Generate inventory of Command Center surfaces"
    cc_surfaces = [f for f in frontend_data if f["is_cc_surface"]]
    
    # Also include "Repositories" used by them?
    # Our scan marked files as "is_cc_surface" if name matched.
    # Repos matching keywords are included.
    
    total_screens = 0
    total_endpoints_referenced = 0
    missing_endpoints = []
    
    for surf in cc_surfaces:
        file_path = surf["file"]
        endpoints = surf["endpoints"]
        
        if not endpoints:
            continue
            
        total_screens += 1
        mapped_endpoints = []
        
        for ep in endpoints:
            total_endpoints_referenced += 1
            if ep in backend_lut:
                # Found in Backend Scan
                matches = backend_lut[ep]
                # Check classification
                classifications = set(m.get("classification") for m in matches)
                
                # Validation: Must have classification and NOT be UNKNOWN
                # Ignore HEAD methods which are auto-generated and often UNKNOWN
                valid_classifications = [
                    m.get("classification") 
                    for m in matches 
                    if m["method"] != "HEAD"
                ]
                
                # If only HEAD exists (rare), then it is UNKNOWN.
                # If GET exists, we trust GET.
                
                if not valid_classifications:
                     # Fallback if only HEAD was found or empty
                     if any(c == "UNKNOWN_ZOMBIE" for c in classifications):
                          validation_errors.append(f"Surface {file_path} calls {ep} which is UNKNOWN (Methods: {[m['method'] for m in matches]})!")
                elif any(c == "UNKNOWN_ZOMBIE" or c is None for c in valid_classifications):
                     validation_errors.append(f"Surface {file_path} calls {ep} which is UNKNOWN!")
                
                mapped_endpoints.append({
                    "path": ep,
                    "methods": [m["method"] for m in matches],
                    "classification": list(set(valid_classifications) if valid_classifications else classifications)
                })
            else:
                # Endpoint referenced in UI but NOT found in Backend Scan
                # This is a GHOST ROUTE (UI Zombie).
                # Stop Condition: "any endpoint referenced by UI is not in ZOMBIE_LEDGER"
                validation_errors.append(f"Surface {file_path} calls GHOST endpoint {ep} (Missing from Backend/Ledger)!")
                
                missing_endpoints.append(f"{file_path} -> {ep}")
                mapped_endpoints.append({
                    "path": ep,
                    "status": "GHOST (MISSING)"
                })
        
        inventory.append({
            "screen": file_path,
            "keywords": surf["keywords"],
            "calls": mapped_endpoints
        })
        
    # Write Inventory
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(inventory, f, indent=2)
        
    # Write Markdown Report
    with open(OUTPUT_MD, "w", encoding="utf-8") as f:
        f.write("# COMMAND CENTER INVENTORY (TRUTH MAP)\n\n")
        f.write(f"**Generated:** D60.1\n")
        f.write(f"**Surfaces:** {total_screens}\n")
        f.write(f"**References:** {total_endpoints_referenced}\n\n")
        
        for item in inventory:
            f.write(f"## Surface: `{item['screen']}`\n")
            f.write(f"- **Keywords:** {', '.join(item['keywords'])}\n")
            f.write(f"- **Dependencies:**\n")
            for call in item["calls"]:
                status = call.get("classification", call.get("status"))
                icon = "✅" if status and status != "MISSING_FROM_BACKEND_SCAN" else "❌"
                f.write(f"  - {icon} `{call['path']}` -> {status}\n")
            f.write("\n")
            
    # Verification Result
    success = (len(validation_errors) == 0)
    
    report = {
        "success": success,
        "errors": validation_errors,
        "missing_scan_coverage": missing_endpoints
    }
    
    with open(REPORT_JSON, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
        
    if not success:
        print("VALIDATION FAILED!")
        for e in validation_errors:
            print(f" - {e}")
        sys.exit(1)
        
    print(f"Inventory Map Generated. {len(missing_endpoints)} Missing from Backend Scan (Check if they are generic).")
    print(f"Success: {success}")

if __name__ == "__main__":
    main()
