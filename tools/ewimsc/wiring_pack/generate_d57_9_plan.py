import os
import sys
import json
from pathlib import Path
from datetime import datetime

# Add repo root to sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

# Configuration
WIRING_PACK_PATH = REPO_ROOT / "outputs/proofs/D57_8_WIRING_PACK/wiring_pack.json"
OUTPUT_DIR = REPO_ROOT / "outputs/proofs/D57_9_UNKNOWN_ZOMBIE_PLAN"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def classify_endpoint(path, methods):
    """
    Applies Constitutional Rules to determine Risk and Recommended State.
    """
    risk = "LOW"
    state = "DEPRECATE" # Default safe removal if unknown
    violation = []
    actions = []
    notes = ""
    blocks = False

    # HIGH RISK PATTERNS (Write, Forensic, Lab Leak)
    if ("/elite/chat" in path or 
        "/elite/settings" in path or 
        "/elite/reflection" in path or
        "/autofix" in path or 
        "/misfire" in path or 
        "/blackbox" in path or
        "/os/state_snapshot" in path or
        "/sunday_setup" in path or
        path.startswith("/lab/") # Catch any lapsed lab routes
       ):
        risk = "HIGH"
        state = "LAB_INTERNAL"
        violation.append("AUTH_AND_GATES")
        actions.append("Shield with 403")
        actions.append("Move behind Founder Key")
        blocks = True
        notes = "Sensitive operation or forensic exposure."

    # MEDIUM RISK (Read-Only but Internal/Unstable)
    elif ("/agms/" in path or 
          "/dojo/" in path or 
          "/immune/" in path or 
          "/tuning/" in path or
          "/elite/" in path # Other elite reads
         ):
        risk = "MEDIUM"
        # Most of these are likely valid internal tools or future products
        # For now, default to LAB_INTERNAL for safety unless clearly public
        state = "LAB_INTERNAL" 
        actions.append("Shield with 403")
        notes = "Internal logic or unstable contract."
        
    # LOW RISK (Safe Reads, UI Support)
    elif ("/events/" in path or 
          "/evidence_summary" in path or 
          "/voice_state" in path or 
          "/overlay_live" in path or
          "/options_report" in path or
          "/on_demand/context" in path or
          "/economic_calendar" in path or
          "/efficacy" in path
         ):
        risk = "LOW"
        state = "PUBLIC_PRODUCT"
        actions.append("Verify Read-Only")
        notes = "Likely safe product surface."

    # Special DEPRECATION candidates
    # Any duplicate or clearly temp alias
    
    return {
        "risk_class": risk,
        "recommended_final_state": state,
        "constitutional_violation": violation,
        "required_actions": actions,
        "blocks_release": blocks,
        "notes": notes
    }


def main():
    print("--- D57.9 ZOMBIE RESOLUTION PLAN ---")
    
    # 1. Load Wiring Pack
    if not WIRING_PACK_PATH.exists():
        print(f"FATAL: Wiring Pack not found at {WIRING_PACK_PATH}")
        sys.exit(1)
        
    data = json.loads(WIRING_PACK_PATH.read_text(encoding="utf-8"))
    inventory = data.get("inventory", [])
    
    # 2. Filter Zombies
    zombies = [i for i in inventory if i["classification"] == "UNKNOWN_ZOMBIE"]
    print(f"Loaded {len(inventory)} endpoints. Found {len(zombies)} UNKNOWN_ZOMBIEs.")
    
    # 3. Generate Resolution Matrix
    resolution_matrix = []
    
    for z in zombies:
        classification = classify_endpoint(z["path"], z["methods"])
        
        entry = {
            "path": z["path"],
            "methods": z["methods"],
            "current_status": "UNKNOWN_ZOMBIE",
            **classification
        }
        resolution_matrix.append(entry)
        
    # Sort by Risk (HIGH -> MEDIUM -> LOW) then Path
    risk_order = {"HIGH": 0, "MEDIUM": 1, "LOW": 2}
    resolution_matrix.sort(key=lambda x: (risk_order[x["risk_class"]], x["path"]))
    
    # 4. Write Outputs
    
    # A. JSON Matrix
    json_path = OUTPUT_DIR / "unknown_zombie_resolution.json"
    json_path.write_text(json.dumps(resolution_matrix, indent=2), encoding="utf-8")
    print(f"Generated {json_path}")
    
    # B. COUNTS MD
    counts = {"HIGH": 0, "MEDIUM": 0, "LOW": 0}
    recs = {}
    
    for r in resolution_matrix:
        counts[r["risk_class"]] += 1
        recs[r["recommended_final_state"]] = recs.get(r["recommended_final_state"], 0) + 1
        
    count_md = [
        "# UNKNOWN ZOMBIE COUNTS",
        f"**Date:** {datetime.now().isoformat()}",
        f"**Total Zombies:** {len(resolution_matrix)}",
        "",
        "## Risk Classification",
        "| Risk Class | Count |",
        "|---|---|",
        f"| HIGH | {counts['HIGH']} |",
        f"| MEDIUM | {counts['MEDIUM']} |",
        f"| LOW | {counts['LOW']} |",
        "",
        "## Recommended Final State",
        "| State | Count |",
        "|---|---|",
    ]
    for k, v in recs.items():
        count_md.append(f"| {k} | {v} |")
        
    md_path = OUTPUT_DIR / "UNKNOWN_ZOMBIE_COUNTS.md"
    md_path.write_text("\n".join(count_md), encoding="utf-8")
    print(f"Generated {md_path}")
    
    # C. SEQUENCE PLAN MD
    seq_md = [
        "# D58 ENDPOINT CLEANUP SEQUENCE",
        "",
        "## Phase 1: High Risk Shield (Immediate)",
        "**Objective:** Lock down all endpoints exposing writing capabilities, forensic data, or sensitive internal logic.",
        "**Target State:** `LAB_INTERNAL` (Strict 403).",
        "**Candidates:**"
    ]
    for r in resolution_matrix:
        if r["risk_class"] == "HIGH":
            seq_md.append(f"- `{r['path']}`")
            
    seq_md.extend([
        "",
        "## Phase 2: Internal Review (Medium Risk)",
        "**Objective:** Verify internal tools and stable artifact readers. Shield as LAB_INTERNAL unless proven product-safe.",
        "**Candidates:**"
    ])
    for r in resolution_matrix:
        if r["risk_class"] == "MEDIUM":
            seq_md.append(f"- `{r['path']}`")
            
    seq_md.extend([
        "",
        "## Phase 3: Product Promotion (Low Risk)",
        "**Objective:** Verify read-only safety/cost and promote to `PUBLIC_PRODUCT`.",
        "**Candidates:**"
    ])
    for r in resolution_matrix:
        if r["risk_class"] == "LOW":
            seq_md.append(f"- `{r['path']}`")
            
    seq_path = OUTPUT_DIR / "D58_SEQUENCE_PLAN.md"
    seq_path.write_text("\n".join(seq_md), encoding="utf-8")
    print(f"Generated {seq_path}")
    
    # D. NOTEBOOKLM TXT
    nb_lines = [
        f"UNKNOWN_ZOMBIES_TOTAL: {len(resolution_matrix)}",
        ""
    ]
    
    nb_lines.append("HIGH_RISK:")
    for r in resolution_matrix:
        if r["risk_class"] == "HIGH": nb_lines.append(f"- {r['path']}")
    
    nb_lines.append("")
    nb_lines.append("MEDIUM_RISK:")
    for r in resolution_matrix:
        if r["risk_class"] == "MEDIUM": nb_lines.append(f"- {r['path']}")
        
    nb_lines.append("")
    nb_lines.append("LOW_RISK:")
    for r in resolution_matrix:
        if r["risk_class"] == "LOW": nb_lines.append(f"- {r['path']}")
        
    nb_lines.append("")
    nb_lines.append("RECOMMENDED_LAB_INTERNAL:")
    for r in resolution_matrix:
        if r["recommended_final_state"] == "LAB_INTERNAL": nb_lines.append(f"- {r['path']}")

    nb_lines.append("")
    nb_lines.append("RECOMMENDED_PUBLIC_PRODUCT:")
    for r in resolution_matrix:
        if r["recommended_final_state"] == "PUBLIC_PRODUCT": nb_lines.append(f"- {r['path']}")
        
    nb_lines.append("")
    nb_lines.append("RECOMMENDED_DEPRECATION:")
    for r in resolution_matrix:
        if r["recommended_final_state"] == "DEPRECATE": nb_lines.append(f"- {r['path']}")
        
    nb_path = OUTPUT_DIR / "NOTEBOOKLM_UNKNOWN_ZOMBIES.txt"
    nb_path.write_text("\n".join(nb_lines), encoding="utf-8")
    print(f"Generated {nb_path}")
    print("SUCCESS")

if __name__ == "__main__":
    main()
