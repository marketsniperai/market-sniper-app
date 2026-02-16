import os
import re
from pathlib import Path

SEALS_DIR = r"C:\MSR\MarketSniperRepo\outputs\seals"
GAP_REPORT_PATH = r"C:\MSR\MarketSniperRepo\RECOVERY_GAP_REPORT.md"

def audit():
    print("Auditing D60/D62 Seals for Code Implementation...")
    
    report_content = "# RECOVERY GAP REPORT: D60 & D62\n\n"
    report_content += "**Date:** 2026-02-17\n"
    report_content += "**Scope:** D60 & D62 Implementation Audit\n\n"
    report_content += "| Seal | Status | Missing Files | Verdict |\n"
    report_content += "|---|---|---|---|\n"

    seal_files = []
    for f in os.listdir(SEALS_DIR):
        if (f.startswith("SEAL_D60") or f.startswith("SEAL_D62")) and f.endswith(".md"):
            seal_files.append(f)
    
    seal_files.sort()
    
    # Regex to find file paths (simplified)
    # Looks for `path/to/file.ext` or just likely paths in metadata lines
    # We focus on lines starting with "- **Key**:" or just generally containing paths
    # We look for extensions: .py, .dart, .json, .md, .sh, .ps1
    path_pattern = re.compile(r'[`]?(?:\.\./)?([a-zA-Z0-9_/-]+\.[a-zA-Z0-9]+)[`]?')

    for seal_name in seal_files:
        full_path = os.path.join(SEALS_DIR, seal_name)
        with open(full_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        referenced_files = set()
        
        # Naive extraction: scan for anything looking like a file path relative to repo root
        # We only care about code files, not the seal itself or other docs unless critical
        matches = path_pattern.findall(content)
        for m in matches:
            # Clean up path
            path = m.replace("../", "").replace("file:///", "").strip()
            # Filter for likely source/config files
            if any(path.endswith(ext) for ext in ['.py', '.dart', '.json', '.yaml', '.sh', '.ps1', '.html']):
                # Ignore self-reference to seal or other seals
                if "outputs/seals/" in path or path.endswith(".md"):
                    continue
                referenced_files.add(path)
        
        missing = []
        present = []
        
        for rf in referenced_files:
            # Check existence
            # Assume paths are relative to repo root C:\MSR\MarketSniperRepo
            abs_path = os.path.join(r"C:\MSR\MarketSniperRepo", rf)
            if os.path.exists(abs_path):
                present.append(rf)
            else:
                missing.append(rf)
        
        verdict = "OK"
        if missing:
            verdict = "NEEDS RESCUE"
        elif not present and not missing:
            verdict = "NO CODE REF"

        # Table Row
        missing_str = "<br>".join([f"`{m}`" for m in missing]) if missing else "None"
        formatted_seal_name = seal_name.replace("SEAL_", "").replace(".md", "")
        formatted_verdict = f"**{verdict}**" if verdict == "NEEDS RESCUE" else verdict
        
        report_content += f"| {formatted_seal_name} | {formatted_verdict} | {missing_str} | {verdict} |\n"
        
        print(f"[{verdict}] {seal_name}: Missing {len(missing)} / Present {len(present)}")

    with open(GAP_REPORT_PATH, "w", encoding="utf-8") as f:
        f.write(report_content)
    
    print(f"\nReport written to {GAP_REPORT_PATH}")

if __name__ == "__main__":
    audit()
