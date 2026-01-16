import os
import re
import sys
import json
import argparse
from pathlib import Path

# --- CONFIG ---
ROOT_DIR = Path(os.getcwd())
OUTPUT_DIR = ROOT_DIR / "backend/outputs/runtime/day_36_1"

# Heuristic Common Spanish Words (with padding to avoid partial matches in code like 'opaque')
# and specific words requested by user.
# Note: "con" matches "console" if not padded. "para" matches "param" if not padded.
PASS_A_KEYWORDS = [
    r"\bque\b", r"\bde\b", r"\bla\b", r"\bel\b", r"\blos\b", r"\blas\b",
    r"\bpara\b", r"\bcon\b", r"\bsin\b", r"\bfase\b", r"\bsello\b",
    r"\bobjetivo\b", r"\bevidencia\b", r"\bmañana\b", r"\bhoy\b",
    r"\bregla\b", r"\bprotocolo\b", r"\bguerra\b", r"\bcomandante\b",
    r"\bcapitan\b", r"\bnosotros\b", r"\bdebe\b", r"\bactivar\b",
    r"\bdesactivar\b", r"\bcierre\b", r"\bverdad\b", r"\bseguro\b",
    r"\briesgo\b", r"\bmitigación\b", r"\bmás\b", r"\btambién\b"
]

# Diacritics
PASS_B_CHARS = [
    "á", "é", "í", "ó", "ú", "ñ", "¿", "¡"
]

EXCLUDE_DIRS = [
    ".git", ".idea", ".vscode", "__pycache__", "build", ".dart_tool", ".gradle", "android/.cxx",
    "node_modules", "backend/outputs"  # Exclude runtime logs (except specific scans if needed)
]

# Specifically Exclude: jsonl files, binary
EXCLUDE_EXTS = [
    ".jsonl", ".png", ".jpg", ".jpeg", ".bmp", ".apk", ".zip", ".tar", ".gz", ".pyc",
    ".jar", ".class", ".ico", ".lock",
    "B_VICTORY_CHECKLIST__RAW.md", "B_VICTORY_CHECKLIST__CLEAN.md", "B_VICTORY_CHECKLIST__DRILLDOWN.md", "B_VICTORY_CHECKLIST__INDEX.md",
    "language_audit.py"
]

INCLUDE_ROOTS = [
    "docs", "backend", "market_sniper_app"
]

def ensure_dir():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def is_excluded(path_str):
    path_str = path_str.replace("\\", "/")
    parts = path_str.split("/")
    
    # Dirs (robust check)
    for d in EXCLUDE_DIRS:
        d_parts = d.replace("\\", "/").split("/")
        # Check if d_parts matches the start of parts
        # e.g. matching "backend/outputs" against "backend/outputs/runtime/..."
        
        # Check if path_str starts with d followed by / or is exactly d
        if path_str == d or path_str.startswith(d + "/"):
            return True
            
        # Also check if any single-folder exclude is in parts (e.g. node_modules anywhere)
        if len(d_parts) == 1 and d in parts:
            return True

    # Legacy specific
    if "legacy" in parts:
        return True
            
    # Extensions
    if any(path_str.endswith(ext) for ext in EXCLUDE_EXTS):
        return True
    
    return False

def scan_file(path):
    hits = []
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
            
        for i, line in enumerate(lines):
            line_clean = line.lower()
            
            # Pass A
            for keyword in PASS_A_KEYWORDS:
                if re.search(keyword, line_clean):
                    hits.append((i+1, f"KEYWORD[{keyword}]", line.strip()))
                    break # One hit per line is enough
            
            # Pass B
            if not hits or hits[-1][0] != i+1: # If not already hit
                for char in PASS_B_CHARS:
                    if char in line_clean:
                        hits.append((i+1, f"DIACRITIC[{char}]", line.strip()))
                        break

    except Exception as e:
        print(f"Error reading {path}: {e}")
        
    return hits, lines

def run_scan():
    ensure_dir()
    
    scanned_files = []
    all_hits = []
    
    # 1. Walk Roots
    for root_name in INCLUDE_ROOTS:
        start_dir = ROOT_DIR / root_name
        if not start_dir.exists(): continue
        
        for root, dirs, files in os.walk(start_dir):
            # Prune excludes in place (only works for single folder names unfortunately)
            # manual check in loop is better
            
            for file in files:
                full_path = Path(root) / file
                rel_path = full_path.relative_to(ROOT_DIR)
                
                if is_excluded(str(rel_path)):
                    continue
                    
                # Scan
                scanned_files.append(str(rel_path))
                hits, content = scan_file(full_path)
                
                for line_num, trigger, snippet in hits:
                     all_hits.append({
                         "file": str(rel_path),
                         "line": line_num,
                         "trigger": trigger,
                         "snippet": snippet,
                         "context": content[max(0, line_num-3):min(len(content), line_num+2)]
                     })
                     
    # 2. Check Root Files (PROJECT_STATE.md, etc)
    for f in ROOT_DIR.glob("*.md"):
         rel_path = f.relative_to(ROOT_DIR)
         if is_excluded(str(rel_path)): continue
         scanned_files.append(str(rel_path))
         hits, content = scan_file(f)
         for line_num, trigger, snippet in hits:
             all_hits.append({
                 "file": str(rel_path),
                 "line": line_num,
                 "trigger": trigger,
                 "snippet": snippet,
                 "context": content[max(0, line_num-3):min(len(content), line_num+2)]
             })

    # 3. Check Contracts (.json in root)
    for f in ROOT_DIR.glob("os_*.json"):
         rel_path = f.relative_to(ROOT_DIR)
         if is_excluded(str(rel_path)): continue
         scanned_files.append(str(rel_path))
         hits, content = scan_file(f)
         for line_num, trigger, snippet in hits:
             all_hits.append({
                 "file": str(rel_path),
                 "line": line_num,
                 "trigger": trigger,
                 "snippet": snippet,
                 "context": content[max(0, line_num-3):min(len(content), line_num+2)]
             })
             
    # Write Artifacts
    
    # List
    with open(OUTPUT_DIR / "repo_scan_file_list.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(scanned_files))
        
    # Raw Hits
    with open(OUTPUT_DIR / "spanish_hits_raw.txt", "w", encoding="utf-8") as f:
        for h in all_hits:
            f.write(f"{h['file']}:{h['line']} [{h['trigger']}] {h['snippet']}\n")
            
    # Context Hits
    with open(OUTPUT_DIR / "spanish_hits_context.txt", "w", encoding="utf-8") as f:
        for h in all_hits:
            f.write(f"=== {h['file']}:{h['line']} [{h['trigger']}] ===\n")
            for cl in h['context']:
                f.write(cl)
            f.write("\n\n")

    # Report
    report = {
        "files_scanned": len(scanned_files),
        "total_hits": len(all_hits),
        "status": "PASS" if len(all_hits) == 0 else "FAIL"
    }
    with open(OUTPUT_DIR / "day_36_1_language_audit_report.json", "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
        
    print(json.dumps(report, indent=2))
    return len(all_hits)

if __name__ == "__main__":
    count = run_scan()
    sys.exit(0 if count == 0 else 1)
