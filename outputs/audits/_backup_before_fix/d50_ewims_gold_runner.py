
import os
import re
import json
import ast
from pathlib import Path
from datetime import datetime

# =============================================================================
# CONFIGURATION & CONSTANTS
# =============================================================================

REPO_ROOT = Path(os.getcwd())
PROJECT_STATE_PATH = REPO_ROOT / "PROJECT_STATE.md"
WAR_CALENDAR_PATH = REPO_ROOT / "docs/canon/OMSR_WAR_CALENDAR__35_45_DAYS.md"
SEALS_DIR = REPO_ROOT / "outputs/seals"
AUDIT_OUTPUT_DIR = REPO_ROOT / "outputs/audits"
AUDIT_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Sources for Truth
API_SERVER_PATH = REPO_ROOT / "backend/api_server.py"
FRONTEND_LIB_PATH = REPO_ROOT / "market_sniper_app/lib"
OUTPUTS_PATH = REPO_ROOT / "outputs"

# =============================================================================
# PHASE 1: HISTORICAL CLAIM EXTRACTION
# =============================================================================

def extract_claims():
    print("--- PHASE 1: HISTORICAL CLAIM EXTRACTION ---")
    claims = []

    # 1. Parse War Calendar
    if WAR_CALENDAR_PATH.exists():
        print(f"Parsing War Calendar: {WAR_CALENDAR_PATH.name}")
        with open(WAR_CALENDAR_PATH, "r", encoding="utf-8") as f:
            lines = f.readlines()
        
        current_day = "Unknown"
        for i, line in enumerate(lines):
            line = line.strip()
            # Detect Day headers or items
            # Pattern: "- [x] D43.00 — Elite First Interaction Script..."
            day_match = re.search(r'-\s*\[x\]\s*(D\d+(\.\d+|[A-Z0-9_\-\.]+)?)', line, re.IGNORECASE)
            if day_match:
                claim_id = day_match.group(1)
                # Cleanup description
                desc = line.replace(f"- [x] {claim_id}", "").strip(" —-:")
                claims.append({
                    "sku": claim_id,
                    "description": desc,
                    "source": "WAR_CALENDAR",
                    "line": i + 1,
                    "day": claim_id.split('.')[0] # D43 from D43.00
                })
            elif line.startswith("## PHASE"):
                pass # Phase headers

    # 2. Parse Project State
    if PROJECT_STATE_PATH.exists():
        print(f"Parsing Project State: {PROJECT_STATE_PATH.name}")
        with open(PROJECT_STATE_PATH, "r", encoding="utf-8") as f:
            lines = f.readlines()
            
        for i, line in enumerate(lines):
            line = line.strip()
            # Pattern: "- [x] D42.01: War Room..." or "- **Day 37:** ..."
            # We want specific sealed items
            if "[x]" in line or "(SEALED)" in line:
                # Try to extract D-number if present
                d_match = re.search(r'(D\d+(\.\d+|[A-Z0-9_\-\.]+)?)', line)
                if d_match:
                    claim_id = d_match.group(1)
                    desc = line.replace(f"- [x] {claim_id}", "").replace("(SEALED)", "").replace("**", "").strip(" —-:")
                    # Avoid duplicates if already found in War Calendar
                    if not any(c['sku'] == claim_id and c['source'] == "WAR_CALENDAR" for c in claims):
                        claims.append({
                            "sku": claim_id,
                            "description": desc,
                            "source": "PROJECT_STATE",
                            "line": i + 1,
                            "day": claim_id.split('.')[0]
                        })

    # 3. Parse Seals
    print(f"Parsing Seals from {SEALS_DIR.name}...")
    if SEALS_DIR.exists():
        for seal_file in SEALS_DIR.glob("SEAL_*.md"):
            # Extract day and feature from filename
            # SEAL_DAY_44_04_ON_DEMAND_SCREEN.md
            parts = seal_file.stem.split('_')
            day_str = "Unknown"
            feature_name = seal_file.stem
            
            # Heuristic for Day
            if "DAY" in parts:
                idx = parts.index("DAY")
                if idx + 1 < len(parts):
                    day_str = f"D{parts[idx+1]}"
            elif force_d_match := re.search(r'SEAL_(D\d+)', seal_file.name):
                day_str = force_d_match.group(1)
                
            # We treat the seal itself as a claim that "X was sealed"
            # We only add if we don't have a specific SKU for it, OR we treat seals as the ultimate list?
            # User said: "For each claim, extract: Day number, Feature name... Output (SSOT)"
            # A merged list is best.
            
            claims.append({
                "sku": seal_file.stem, # Use filename as SKU if no mapping
                "description": f"Seal Artifact: {seal_file.name}",
                "source": "SEAL_FILE",
                "line": 0,
                "day": day_str,
                "file_path": str(seal_file)
            })

    # Deduplication and Cleaning
    # If we have a "D43.00" from War Calendar and a "SEAL_DAY_43_00..." we should link them or list both?
    # User said: "If a day has multiple features, extract ALL of them."
    # I will keep them all but group them in the final matrix.
    
    # Save Promise Index
    out_path = AUDIT_OUTPUT_DIR / "D50_EWIMS_PROMISES_INDEX.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(claims, f, indent=2)
    
    print(f"Total Claims Extracted: {len(claims)}")
    return claims

# =============================================================================
# PHASE 2: REALITY SCAN (THE AUTOPSY)
# =============================================================================

def build_indices():
    print("Building Forensic Indices...")
    indices = {
        "endpoints": [],
        "files": [],
        "artifacts": [],
        "classes": []
    }

    # 1. Index Endpoints
    if API_SERVER_PATH.exists():
        with open(API_SERVER_PATH, "r", encoding="utf-8") as f:
            content = f.read()
            matches = re.finditer(r'@app\.(get|post|put|delete)\(["\']([^"\']+)["\']', content)
            for m in matches:
                indices["endpoints"].append(m.group(2))

    # 2. Index Files & Classes
    for root, dirs, files in os.walk(REPO_ROOT):
        # Skip hidden/build dirs
        if ".git" in dirs: dirs.remove(".git")
        if "build" in dirs: dirs.remove("build")
        if ".dart_tool" in dirs: dirs.remove(".dart_tool")
        if "node_modules" in dirs: dirs.remove("node_modules")

        for file in files:
            path = Path(root) / file
            rel_path = path.relative_to(REPO_ROOT)
            indices["files"].append(str(rel_path).replace("\\", "/"))
            
            # Dart Classes
            if file.endswith(".dart"):
                try:
                    with open(path, "r", encoding="utf-8", errors="ignore") as f:
                        c = f.read()
                        class_matches = re.finditer(r'class\s+(\w+)', c)
                        for cm in class_matches:
                            indices["classes"].append(cm.group(1))
                except: pass

    # 3. Index Artifacts (OUTPUTS)
    if OUTPUTS_PATH.exists():
        for root, dirs, files in os.walk(OUTPUTS_PATH):
            for file in files:
                path = Path(root) / file
                rel_path = path.relative_to(REPO_ROOT)
                indices["artifacts"].append(str(rel_path).replace("\\", "/"))

    return indices

def verify_claim(claim, indices):
    # Logic to determine ALIVE, ZOMBIE, GHOST
    # Returns (status, evidence)
    
    sku = claim["sku"].lower()
    desc = claim["description"].lower()
    
    # Heuristic 1: SKU or Desc matches a File Name
    # Normalize SKU: D44.04 -> d44_04, on-demand -> on_demand
    keywords = re.split(r'[\._\-\s]', sku) + re.split(r'[\._\-\s]', desc)
    keywords = [k for k in keywords if len(k) > 3 and k not in ["seal", "day", "sealed", "implemented", "verified", "feature"]]
    
    # Search Files
    for kw in keywords:
        for f in indices["files"]:
            if kw in f.lower():
                 return "ALIVE", f"File Match: {f}"
                 
    # Search Classes (Stronger)
    for kw in keywords:
        # CamelCase check
        for c in indices["classes"]:
            if kw in c.lower():
                return "ALIVE", f"Class Match: {c}"

    # Search Endpoints
    for kw in keywords:
        for ep in indices["endpoints"]:
            if kw in ep.lower():
                return "ALIVE", f"Endpoint Match: {ep}"

    # Search Artifacts
    for kw in keywords:
        for art in indices["artifacts"]:
            if kw in art.lower():
                return "ALIVE", f"Artifact Match: {art}"

    # Verify via specific Seal File existence (Self-Referential but valid if the seal exists)
    # The PROMISE is the line in the calendar. The PROOF is the seal. 
    # But checking if the FEATURE exists is stricter.
    # If we only find the seal, it might be a GHOST feature (sealed but no code).
    # So finding the seal file is NOT enough to prove ALIVE code. 
    
    # If no code/artifact/endpoint found -> GHOST
    return "GHOST", "No code, endpoint, or artifact trace found."

def run_verification(claims, indices):
    print("--- PHASE 2: REALITY SCAN ---")
    results = []
    
    # Sort claims by Day
    # Normalize Day to D0, D1... D50
    def parse_day(d_str):
        if not d_str: return -1
        m = re.match(r'D(\d+)', d_str, re.IGNORECASE)
        if m: return int(m.group(1))
        return 999
        
    sorted_claims = sorted(claims, key=lambda c: parse_day(c.get("day")))
    
    # Prepare Stats
    stats = {"ALIVE": 0, "ZOMBIE": 0, "GHOST": 0}
    
    for claim in sorted_claims:
        status, evidence = verify_claim(claim, indices)
        
        # Refine ZOMBIE logic: 
        # If evidence is weak or matches a "DEPRECATED" file?
        if "deprecated" in evidence.lower():
            status = "ZOMBIE"
            
        stats[status] += 1
        
        results.append({
            "day": claim.get("day", "Unknown"),
            "feature": claim["sku"], # or description
            "description": claim["description"],
            "status": status,
            "evidence": evidence
        })
        
    return results, stats

# =============================================================================
# PHASE 3-6: OUTPUT GENERATION
# =============================================================================

def generate_reports(results, stats):
    print("--- PHASE 3-6: REPORT GENERATION ---")
    
    # 1. Chronological Matrix
    tuples = []
    for r in results:
        tuples.append(f"| {r['day']} | {r['description'][:60]}... | {r['status']} | {r['evidence']} |")
        
    matrix_path = AUDIT_OUTPUT_DIR / "D50_EWIMS_CHRONOLOGICAL_MATRIX.md"
    with open(matrix_path, "w", encoding="utf-8") as f:
        f.write("# D50 EWIMS CHRONOLOGICAL TRUTH MATRIX\n\n")
        f.write("| Day | Feature Claim | Status | Hard Evidence |\n")
        f.write("| :--- | :--- | :--- | :--- |\n")
        f.write("\n".join(tuples))
        
    # 2. Ghost/Zombie List
    gz_path = AUDIT_OUTPUT_DIR / "D50_EWIMS_GHOST_ZOMBIE_LIST.md"
    with open(gz_path, "w", encoding="utf-8") as f:
        f.write("# D50 EWIMS HIT LIST (GHOSTS & ZOMBIES)\n\n")
        gz = [r for r in results if r["status"] in ["GHOST", "ZOMBIE"]]
        if not gz:
            f.write("No Ghosts or Zombies detected. System is GOLD.\n")
        for item in gz:
            f.write(f"- [{item['status']}] **{item['day']} - {item['description']}**\n")
            f.write(f"  - Evidence: {item['evidence']}\n")

    # 3. Coverage Summary
    summary = {
        "check_date": datetime.now().isoformat(),
        "total_claims": len(results),
        "alive": stats["ALIVE"],
        "zombie": stats["ZOMBIE"],
        "ghost": stats["GHOST"],
        "verdict": "FAIL" 
    }
    
    if stats["GHOST"] == 0 and stats["ZOMBIE"] == 0:
        summary["verdict"] = "PASS"
    elif stats["GHOST"] == 0 and stats["ZOMBIE"] > 0:
        summary["verdict"] = "CONDITIONAL"
        
    sum_path = AUDIT_OUTPUT_DIR / "D50_EWIMS_COVERAGE_SUMMARY.json"
    with open(sum_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)

    # 4. Final Verdict
    v_path = AUDIT_OUTPUT_DIR / "D50_EWIMS_FINAL_VERDICT.md"
    with open(v_path, "w", encoding="utf-8") as f:
        f.write(f"# OPERATION EWIMS-GOLD.V2 FINAL VERDICT\n\n")
        f.write(f"**VERDICT: {summary['verdict']}**\n\n")
        f.write(f"## METRICS\n")
        f.write(f"- Total Claims: {summary['total_claims']}\n")
        f.write(f"- Alive: {summary['alive']}\n")
        f.write(f"- Zombie: {summary['zombie']}\n")
        f.write(f"- Ghost: {summary['ghost']}\n\n")
        
        if summary["verdict"] == "PASS":
            f.write("The System is INSTITUTIONALLY COMPLETE. All claims verified.\n")
        elif summary["verdict"] == "CONDITIONAL":
            f.write("The System is FUNCTIONAL but requires HYGIENE cleanup (Zombies detected).\n")
        else:
            f.write("The System is NOT READY. Historical promises are missing (Ghosts detected).\n")

    print("Generation Complete.")

def main():
    claims = extract_claims()
    indices = build_indices()
    results, stats = run_verification(claims, indices)
    generate_reports(results, stats)

if __name__ == "__main__":
    main()
