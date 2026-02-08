import json
import sys
from pathlib import Path

# Add repo root to sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

TRIAGE_PATH = REPO_ROOT / "outputs/proofs/D57_5_ZOMBIE_TRIAGE/zombie_report.json"
INVENTORY_PATH = REPO_ROOT / "outputs/proofs/D58_2_UNKNOWN_INVENTORY/unknown_inventory.json"
OUTPUT_DIR = REPO_ROOT / "outputs/proofs/D58_3_UNKNOWN_WIRING"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def main():
    print("--- D58.3 WIRING RECOVERY GENERATOR ---")

    # 1. Load Data
    if not TRIAGE_PATH.exists() or not INVENTORY_PATH.exists():
        print("FATAL: Missing input files.")
        sys.exit(1)

    triage_data = json.loads(TRIAGE_PATH.read_text(encoding="utf-8"))
    inventory_data = json.loads(INVENTORY_PATH.read_text(encoding="utf-8"))

    # 2. Consistency Check
    triage_zombies = [r for r in triage_data.get("routes", []) if r["status"] == "UNKNOWN_ZOMBIE"]
    inv_zombies = inventory_data # Assuming list of inventory items

    count_triage = len(triage_zombies)
    count_inv = len(inv_zombies)
    
    # Filter inventory to only those that are supposedly unknowns (just in case)
    # The inventory generation script filtered for UNKNOWN_ZOMBIE from triage, so inv should match.
    
    print(f"Triage Zombies: {count_triage}")
    print(f"Inventory Items: {count_inv}")

    if count_triage != count_inv:
        print("FATAL: Count Mismatch!")
        # Generate mismatch report
        mismatch_report = {
            "triage_count": count_triage,
            "inventory_count": count_inv,
            "error": "Divergent Truth"
        }
        (OUTPUT_DIR / "mismatch_report.json").write_text(json.dumps(mismatch_report, indent=2), encoding="utf-8")
        sys.exit(1)

    print("Consistency Check: PASS")

    # 3. Build Wiring Matrix
    matrix = []
    
    for item in inv_zombies:
        path = item["normalized_path"]
        behavior = item.get("behavior_type", "UNKNOWN")
        writes = item.get("writes_artifacts", [])
        
        strategy = "STRAT_B_COMPUTE_TO_ARTIFACT" # Default assumption for compute
        
        if behavior == "READ_ARTIFACT":
            strategy = "STRAT_A_ARTIFACT_READ_ONLY"
        elif behavior == "WRITE_STATE":
            strategy = "STRAT_D_GATED_WRITE"
        elif behavior == "COMPUTE_ON_DEMAND":
            # Heuristic: If it computes, we want it to eventually be artifact-backed or pipeline owned
            # For now, we label it COMPUTE_TO_ARTIFACT so we know it creates data
            strategy = "STRAT_B_COMPUTE_TO_ARTIFACT"
            
        # Refine Strategy based on Path knowledge (Manual knowledge injection or heuristics)
        # For D58.3 we just want to MAP it, not re-architect deeply yet.
        
        matrix_item = {
            "path": path,
            "strategy": strategy,
            "current_behavior": behavior,
            "primary_artifact": "TBD" # Will need manual refinement or lookup if we want exact filenames
        }
        
        matrix.append(matrix_item)

    # 4. Outputs
    (OUTPUT_DIR / "wiring_matrix.json").write_text(json.dumps(matrix, indent=2), encoding="utf-8")
    
    md_lines = [
        "| Path | Strategy | Behavior |",
        "|---|---|---|"
    ]
    for m in matrix:
        md_lines.append(f"| `{m['path']}` | `{m['strategy']}` | `{m['current_behavior']}` |")
        
    (OUTPUT_DIR / "wiring_matrix.md").write_text("\n".join(md_lines), encoding="utf-8")
    
    print(f"Generated Wiring Matrix for {len(matrix)} routes.")

if __name__ == "__main__":
    main()
