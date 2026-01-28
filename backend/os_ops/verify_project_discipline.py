import os
import re
import json
import sys
from pathlib import Path
import verify_dashboard_layout_discipline

# --- CONFIG ---
ROOT_DIR = Path(os.getcwd())
DOCS_CANON = ROOT_DIR / "docs/canon"
BACKEND_OPS = ROOT_DIR / "backend/os_ops"
MARKET_SNIPER_APP = ROOT_DIR / "market_sniper_app"
LIB_DIR = MARKET_SNIPER_APP / "lib"
OUTPUTS_RUNTIME = ROOT_DIR / "outputs/runtime"

CONSTITUTION_FILE = DOCS_CANON / "ANTIGRAVITY_CONSTITUTION.md"
CANON_INDEX = DOCS_CANON / "CANON_INDEX.md"

# --- VERIFIERS ---

def verify_canon_existence():
    """Checks if Supreme Law files exist."""
    missing = []
    
    # 1. Constitution & Index
    if not CONSTITUTION_FILE.exists(): missing.append(str(CONSTITUTION_FILE))
    if not CANON_INDEX.exists(): missing.append(str(CANON_INDEX))
    
    # 2. Check files listed in Canon Index (Simple parse)
    # This is a basic check to ensure the index isn't pointing to ghosts
    if CANON_INDEX.exists():
        with open(CANON_INDEX, "r", encoding="utf-8") as f:
            for line in f:
                if "|" in line and "`" in line:
                    # Extract path between backticks
                    match = re.search(r'`([^`]+)`', line)
                    if match:
                        path_str = match.group(1)
                        if not (ROOT_DIR / path_str).exists():
                            missing.append(f"{path_str} (Referenced in Canon Index)")

    return missing

def scan_ui_hardcodes():
    """Scans lib/ for hardcoded Colors.red or Color(0x...)."""
    violations = []
    
    # Files to exclude from color check (The Truth sources)
    exclusions = [
        "app_colors.dart",
        "app_typography.dart",
        "app_theme.dart" # If exists
    ]
    
    # Patterns to catch
    # 1. Colors.red, Colors.blue, etc. (Material colors)
    # 2. Color(0xFF...) or Color(0x...)
    # 3. Color.fromRGBO(...)
    
    regex_material = re.compile(r'Colors\.(red|green|blue|yellow|black|white|grey|amber|cyan|purple|indigo|lime|orange|pink|teal)')
    regex_hex = re.compile(r'Color\(0x')
    regex_rgb = re.compile(r'Color\.from')

    for root, _, files in os.walk(LIB_DIR):
        for file in files:
            if not file.endswith(".dart"): continue
            if file in exclusions: continue
            
            path = Path(root) / file
            rel_path = path.relative_to(ROOT_DIR)
            
            try:
                with open(path, "r", encoding="utf-8") as f:
                    lines = f.readlines()
                    for i, line in enumerate(lines):
                        line_num = i + 1
                        val = line.strip()
                        
                        hint = ""
                        if regex_material.search(val):
                            color_match = regex_material.search(val).group(0)
                            hint = f"Found '{color_match}'. Use a semantic token from AppColors (e.g., AppColors.stateError for red)."
                        elif regex_hex.search(val):
                            hint = f"Found raw Hex Color. Define this token in app_colors.dart first."
                        elif regex_rgb.search(val):
                            hint = f"Found raw RGB Color. Define this token in app_colors.dart first."
                            
                        if hint:
                            violations.append({
                                "file": str(rel_path),
                                "line": line_num,
                                "code": val,
                                "correction_hint": hint
                            })
            except Exception as e:
                print(f"Error reading {rel_path}: {e}")
                
    return violations

def verify_untracked_canon():
    """Checks if any canonical outputs (seals/proofs) are untracked."""
    import subprocess
    
    untracked_violations = []
    
    try:
        # Check for untracked files
        result = subprocess.run(["git", "status", "--porcelain"], cwd=ROOT_DIR, capture_output=True, text=True)
        lines = result.stdout.splitlines()
        
        for line in lines:
            if line.startswith("?? "):
                path = line[3:].strip('"')
                path_obj = Path(path)
                
                # Check specific directories
                if "outputs/seals/" in path or "outputs/proofs/" in path:
                     untracked_violations.append(path)
                     
    except Exception as e:
        print(f"Error running git status: {e}")
        return []

    return untracked_violations

def verify_seal_hooks():
    """Checks if new SEALs contain the mandatory 'Pending Closure Hook'."""
    seal_dir = ROOT_DIR / "outputs/seals"
    violations = []
    
    enforcement_start_date = "2026-01-28"
    
    # Legacy Exemptions (Bad dates or historic files)
    legacy_exemptions = [
        "SEAL_BUILD_RELEASE_APK_TO_ONEDRIVE.md",
        "SEAL_D31_1_TOPBAR_LOGO_AND_TYPOGRAPHY.md",
        "SEAL_DAY_30_1_FREEZE_CORE_OS_KILL_SWITCHES_RELEASE_CHECKLIST.md",
        "SEAL_DAY_30_2_SURGEON_2VOTE_CONSENSUS.md",
        "SEAL_DAY_31_1_CANON_SYNC_POST_SURGEON.md",
        "SEAL_DAY_31_2_ANTIGRAVITY_CONSTITUTION_AND_DISCIPLINE.md",
        "SEAL_DAY_31_THE_SURGEON_RUNTIME_SELF_REPAIR.md",
        "SEAL_Dxx_UI_LEATHER_BARS_ONLY.md",
        "SEAL_UI_CANON_V1_THEME_TYPOGRAPHY_SHELL.md"
    ]

    try:
        if not seal_dir.exists(): return []
        
        for file in seal_dir.glob("SEAL_*.md"):
            if file.name in legacy_exemptions: continue
            
            with open(file, "r", encoding="utf-8") as f:
                content = f.read()
                
            # Check Date
            date_match = re.search(r'\*\*Date:\s*\*\*\s*(\d{4}-\d{2}-\d{2})', content)
            if not date_match:
                 # If no date found, skip legacy
                 continue
                 
            file_date = date_match.group(1)
            # print(f"DEBUG: {file.name} -> {file_date}")
            
            # Hook V2 Enforcement (Start 2026-01-27)
            if file_date < enforcement_start_date:
                continue

            # If we are here, date is >= 2026-01-27, so we enforce.
            has_header = "## Pending Closure Hook" in content
            has_resolved = "Resolved Pending Items:" in content
            has_new = "New Pending Items:" in content
            
            if not (has_header and has_resolved and has_new):
                violations.append(f"{file.name} (V2 STRICT: Missing 'Resolved'/'New' items)")

    except Exception as e:
        print(f"Error validating seals: {e}")
        
    return violations


def generate_report(canon_missing, ui_violations, untracked_canon, seal_violations):
    passed = (len(canon_missing) == 0) and (len(ui_violations) == 0) and (len(untracked_canon) == 0) and (len(seal_violations) == 0)
    
    report = {
        "status": "PASS" if passed else "FAIL",
        "canon_check": {
            "status": "PASS" if not canon_missing else "FAIL",
            "missing_files": canon_missing
        },
        "ui_discipline": {
            "status": "PASS" if not ui_violations else "FAIL",
            "violation_count": len(ui_violations),
            "violations": ui_violations
        },
        "untracked_canon_check": {
            "status": "PASS" if not untracked_canon else "FAIL",
            "violations": untracked_canon
        },
        "seal_hook_check": {
            "status": "PASS" if not seal_violations else "FAIL",
            "violations": seal_violations
        }
    }
    
    # Print Human Friendly Output
    print("\n" + "="*60)
    print(f"ANTIGRAVITY DISCIPLINE VERIFIER -- STATUS: {report['status']}")
    print("="*60)
    
    if canon_missing:
        print("\n[!] CRITICAL: MISSING CANON FILES")
        for f in canon_missing:
            print(f"  - {f}")
            
    if ui_violations:
        print("\n[!] UI DISCIPLINE VIOLATIONS (Hardcoded Colors)")
        for v in ui_violations:
            print(f"  File: {v['file']}:{v['line']}")
            print(f"  Code: {v['code']}")
            print(f"  >> HINT: {v['correction_hint']}")
            print("-" * 40)

    if untracked_canon:
        print("\n[!] CRITICAL: UNTRACKED CANON OUTPUTS DETECTED")
        for f in untracked_canon:
            print(f"  - {f}")
        print("\n>> ACTION REQUIRED: Run `python tool/auto_stage_canon_outputs.py`")
        
    if seal_violations:
        print("\n[!] SEALS MISSING CLOSURE HOOK (PENDING LAW)")
        for f in seal_violations:
            print(f"  - {f}")
        print("\n>> ACTION REQUIRED: Add '## Pending Closure Hook' to these seals.")
            
    if passed:
        print("\n[+] All Systems Nominal. Discipline is maintained.")
        print("[+] Constitution respected. UI is semantic. Canon is tracked. Seals are Hooked.")

    # Save JSON
    out_dir = OUTPUTS_RUNTIME / "day_31_2"
    os.makedirs(out_dir, exist_ok=True)
    with open(out_dir / "day_31_2_verify.json", "w") as f:
        json.dump(report, f, indent=2)
        
    return passed

if __name__ == "__main__":
    print("Initializing Antigravity Discipline Check...")
    missing = verify_canon_existence()
    violations = scan_ui_hardcodes()
    untracked_canon = verify_untracked_canon()
    seal_violations = verify_seal_hooks()
    success = generate_report(missing, violations, untracked_canon, seal_violations)
    if success:
        success = verify_dashboard_layout_discipline.scan_and_report()
    
    if not success:
        sys.exit(1)
