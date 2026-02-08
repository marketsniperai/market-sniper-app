import os
import json
import re
from pathlib import Path

# Paths
ROOT_DIR = Path(os.getcwd())
SEALS_DIR = ROOT_DIR / "outputs" / "seals"
OUTPUT_JSON = ROOT_DIR / "outputs" / "proofs" / "D56_EWIMSC" / "raw_claims.json"
OUTPUT_MD = ROOT_DIR / "docs" / "canon" / "EWIMSC.md"
OS_MODULES_MD = ROOT_DIR / "docs" / "canon" / "OS_MODULES.md"
OS_FEATURES_MD = ROOT_DIR / "docs" / "canon" / "OS_FEATURES.md"

def parse_seal_filename(filename):
    # Remove extension
    name = filename.replace(".md", "")
    
    # regex for Dxx.xx patterns
    # Standard: SEAL_DAY_42_04_AUTOFIX_TIER1
    match_std = re.match(r"SEAL_DAY_(\d+)_(\d+)[_]?(.*)", name)
    if match_std:
        day = match_std.group(1)
        sub = match_std.group(2)
        desc = match_std.group(3)
        return f"D{day}.{sub}.{desc}", f"Day {day} Sub {sub}", desc

    # Day only: SEAL_DAY_42_GIT_HYGIENE_FIX
    match_day = re.match(r"SEAL_DAY_(\d+)[_]?(.*)", name)
    if match_day:
        day = match_day.group(1)
        desc = match_day.group(2)
        return f"D{day}.{desc}", f"Day {day}", desc

    # Sub-decimal style: SEAL_D56_01_10_CLOUD_RUN...
    match_d_sub = re.match(r"SEAL_D(\d+)_(\d+)_(\d+)[_]?(.*)", name)
    if match_d_sub:
        day = match_d_sub.group(1)
        major = match_d_sub.group(2)
        minor = match_d_sub.group(3)
        desc = match_d_sub.group(4)
        return f"D{day}.{major}.{minor}.{desc}", f"D{day}.{major}", desc

    # Standard D style: SEAL_D56_01_UNIFIED...
    match_d = re.match(r"SEAL_D(\d+)_(\d+)[_]?(.*)", name)
    if match_d:
        day = match_d.group(1)
        major = match_d.group(2)
        desc = match_d.group(3)
        return f"D{day}.{major}.{desc}", f"D{day}.{major}", desc

    # Dxy style: SEAL_D53_WAR_ROOM...
    match_dx = re.match(r"SEAL_D(\d+)[_]?(.*)", name)
    if match_dx:
        day = match_dx.group(1)
        desc = match_dx.group(2)
        return f"D{day}.{desc}", f"D{day}", desc
        
    return name, "Unclassified", name

def generate_registry():
    claims = []
    
    # 1. Scan Seals
    if not SEALS_DIR.exists():
        print("Seals dir not found")
        return

    files = sorted([f.name for f in SEALS_DIR.glob("*.md")])
    
    for f in files:
        cid, group, desc = parse_seal_filename(f)
        claims.append({
            "id": cid,
            "seal": f,
            "group": group,
            "description": desc.replace("_", " ").title(),
            "status": "PENDING", # Default
            "type": "UNKNOWN"
        })

    # 2. Write JSON
    with open(OUTPUT_JSON, "w", encoding="utf-8") as jf:
        json.dump(claims, jf, indent=2)
        
    # 3. Write Markdown Registry
    with open(OUTPUT_MD, "w", encoding="utf-8") as md:
        md.write("# EWIMSC — EVERYTHING WORKS IN MARKET SNIPER CARAJO\n\n")
        md.write("**Single Source of Truth Registry**\n")
        md.write(f"**Total Claims:** {len(claims)}\n")
        md.write("**Last Updated:** 2026-02-05\n\n")
        
        md.write("| Claim ID | Description | Seal Source | Category | Status |\n")
        md.write("| :--- | :--- | :--- | :--- | :--- |\n")
        
        for c in claims:
            # Guess category based on keywords
            cat = "FEATURE"
            desc_lower = c['description'].lower()
            if "engine" in desc_lower or "module" in desc_lower: cat = "MODULE"
            elif "ui" in desc_lower or "screen" in desc_lower or "widget" in desc_lower or "tile" in desc_lower: cat = "UI"
            elif "protocol" in desc_lower or "api" in desc_lower or "endpoint" in desc_lower: cat = "PROTOCOL"
            elif "audit" in desc_lower or "verify" in desc_lower or "smoke" in desc_lower: cat = "AUDIT"
            elif "fix" in desc_lower or "hotfix" in desc_lower: cat = "FIX"
            
            md.write(f"| **{c['id']}** | {c['description']} | `{c['seal']}` | {cat} | **{c['status']}** |\n")

    # 4. Write OS_FEATURES (Subset)
    with open(OS_FEATURES_MD, "w", encoding="utf-8") as fd:
        fd.write("# OS FEATURES REGISTRY\n\n")
        fd.write("**Extracted from EWIMSC (Seals-First)**\n\n")
        fd.write("| Feature ID | Description | Seal |\n")
        fd.write("| :--- | :--- | :--- |\n")
        for c in claims:
             desc_lower = c['description'].lower()
             if "ui" in desc_lower or "feature" in desc_lower or "protocol" in desc_lower:
                  fd.write(f"| **{c['id']}** | {c['description']} | `{c['seal']}` |\n")

    print(f"Generated registry with {len(claims)} claims.")

if __name__ == "__main__":
    generate_registry()
