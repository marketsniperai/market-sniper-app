
import json
import datetime
from pathlib import Path

def update_index():
    path = Path("outputs/proofs/canon/pending_index_v2.json")
    if not path.exists():
        print(f"Index not found at {path}")
        return

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    updates = {
        "PEND_BRAIN_ATTRIBUTION": "SEAL_D48_BRAIN_02_ATTRIBUTION_ENGINE_V1.md",
        "PEND_BRAIN_SURFACE_ADAPTERS": "SEAL_D48_BRAIN_03_SURFACE_ADAPTERS_V1_ON_DEMAND.md",
        "PEND_BRAIN_RELIABILITY_LEDGER": "SEAL_D48_BRAIN_04_RELIABILITY_LEDGER_GLOBAL_TRUTH.md",
        "PEND_BRAIN_DATAMUX": "SEAL_D48_BRAIN_05_PROVIDER_DATAMUX_V1.md",
        "PEND_BRAIN_EVENT_ROUTER": "SEAL_D48_BRAIN_06_EVENT_ROUTER_V1.md",
        "PEND_INFRA_PROVIDER_APIS_BOOTSTRAP": "SEAL_D48_BRAIN_05_PROVIDER_DATAMUX_V1.md"
    }
    
    utc_now = datetime.datetime.utcnow().isoformat()
    count = 0
    
    for module in data.get("modules", []):
        for item in module.get("items", []):
            if item["id"] in updates:
                item["status"] = "RESOLVED"
                item["resolved_by_seal"] = updates[item["id"]]
                item["resolved_at_utc"] = utc_now
                count += 1
                
    # Update totals
    data["meta"]["counts"]["total_active"] = data["meta"]["counts"]["total_active"] - count
    
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        
    print(f"Updated {count} items.")

if __name__ == "__main__":
    update_index()
