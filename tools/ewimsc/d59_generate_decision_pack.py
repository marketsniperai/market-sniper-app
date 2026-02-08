import json
import os
import sys
import re
from pathlib import Path

# Paths
REPO_ROOT = Path(__file__).parent.parent.parent
ZOMBIE_REPORT_FILE = REPO_ROOT / "outputs/proofs/D57_5_ZOMBIE_TRIAGE/zombie_report.json"
DECISION_PACK_DIR = REPO_ROOT / "outputs/proofs/D59_DECISION_PACK"
BACKLOG_FILE = REPO_ROOT / "docs/canon/D59_UNKNOWN_BACKLOG.json"

def classify_route(route):
    path = route["normalized_path"]
    method = route["methods"][0]
    
    # Heuristics
    classification = "MANUAL_REVIEW"
    justification = "Unknown"
    target_class = "UNKNOWN_ZOMBIE" # Default

    if path.startswith("/lab/") or path.startswith("/blackbox/") or path.startswith("/immune/") or path.startswith("/dojo/"):
        classification = "LAB_INTERNAL"
        target_class = "LAB_INTERNAL"
        justification = "Ops/Forensics path"
        
    elif path.startswith("/elite/"):
        if method == "POST" or "chat" in path or "reflection" in path or "settings" in path:
            classification = "ELITE_GATED"
            target_class = "UNKNOWN_ZOMBIE" # Needs Elite Policy + Allowlist update manually
            justification = "Elite Cost/Write"
        else:
             # Elite Read defaults to Lab unless Public Safe
             classification = "ELITE_READ"
             target_class = "UNKNOWN_ZOMBIE" 
             justification = "Elite Read (Check safety)"

    elif path.startswith("/agms/"):
        classification = "PUBLIC_CANDIDATE"
        target_class = "PUBLIC_PRODUCT"
        justification = "AGMS Read-Only"
        
    elif method == "GET":
         classification = "POTENTIAL_PUBLIC"
         target_class = "PUBLIC_PRODUCT"
         justification = "General GET"
         
    return target_class, classification, justification

def generate_decision_pack():
    print("--- D59 DECISION PACK GENERATOR ---")
    
    DECISION_PACK_DIR.mkdir(parents=True, exist_ok=True)
    
    if not ZOMBIE_REPORT_FILE.exists():
        print(f"FAIL: Report missing at {ZOMBIE_REPORT_FILE}")
        sys.exit(1)
        
    with open(ZOMBIE_REPORT_FILE, "r") as f:
        data = json.load(f)
        
    unknowns = [r for r in data["routes"] if r["status"] == "UNKNOWN_ZOMBIE"]
    print(f"Found {len(unknowns)} Unknown Zombies.")
    
    # 1. Backlog Lock (If not exists)
    if not BACKLOG_FILE.exists():
        print(f"Locking Backlog to {BACKLOG_FILE}...")
        backlog = {
            "locked_at": "D59_INIT",
            "count": len(unknowns),
            "routes": unknowns
        }
        with open(BACKLOG_FILE, "w") as f:
            json.dump(backlog, f, indent=2)
    else:
        print("Backlog already locked.")
        
    # 2. Decision Logic
    decisions = []
    
    for route in unknowns:
        target, cls, just = classify_route(route)
        
        item = {
            "path": route["normalized_path"],
            "method": route["methods"][0],
            "current_status": "UNKNOWN_ZOMBIE",
            "proposed_class": target,
            "category": cls,
            "reason": just,
            "actions": [
                f"Update zombie_allowlist.json to {target}",
                "Ensure Artifact Backing or Caching",
                "Add to Contracts (if Public)"
            ]
        }
        decisions.append(item)
        
    # 3. Output JSON
    out_json = DECISION_PACK_DIR / "d59_decision_pack.json"
    with open(out_json, "w") as f:
        json.dump(decisions, f, indent=2)
        
    # 4. Output Markdown
    out_md = DECISION_PACK_DIR / "d59_decision_pack.md"
    with open(out_md, "w") as f:
        f.write("# D59 Decision Pack\n\n")
        f.write(f"**Total Unknowns:** {len(unknowns)}\n\n")
        f.write("| Path | Method | Proposal | Category | Reason |\n")
        f.write("| :--- | :--- | :--- | :--- | :--- |\n")
        
        for d in decisions:
            f.write(f"| `{d['path']}` | {d['method']} | **{d['proposed_class']}** | {d['category']} | {d['reason']} |\n")
            
    print(f"Generated Decision Pack at {DECISION_PACK_DIR}")

if __name__ == "__main__":
    generate_decision_pack()
