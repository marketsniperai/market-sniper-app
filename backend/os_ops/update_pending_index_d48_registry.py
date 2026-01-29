
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

    utc_now = datetime.datetime.utcnow().isoformat()
    count = 0
    
    for module in data.get("modules", []):
        for item in module.get("items", []):
            if item["id"] == "PEND_REGISTRY_PATH":
                item["status"] = "RESOLVED"
                item["resolved_by_seal"] = "SEAL_D48_OPS_PEND_REGISTRY_PATH.md"
                item["resolved_at_utc"] = utc_now
                count += 1
                
    if count > 0:
        data["meta"]["counts"]["total_active"] = data["meta"]["counts"]["total_active"] - count
    
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        
    print(f"Updated {count} items.")

if __name__ == "__main__":
    update_index()
