import os
import re
import sys
import json
from pathlib import Path

# --- CONFIG ---
ROOT_DIR = Path(os.getcwd())
MARKET_SNIPER_APP = ROOT_DIR / "market_sniper_app"
LIB_DIR = MARKET_SNIPER_APP / "lib"
DASHBOARD_DIR = LIB_DIR / "screens/dashboard"
DASHBOARD_SCREEN_FILE = LIB_DIR / "screens/dashboard_screen.dart"

# Exceptions for Rule 2 (No EdgeInsets literals)
# This file defines the tokens, so it MUST contain literals.
SPACING_TOKENS_FILE = LIB_DIR / "ui/tokens/dashboard_spacing.dart"

def scan_dashboard_layout():
    """
    Scans dashboard files for layout discipline violations.
    Returns a dict with status and violations.
    """
    violations = []
    
    # --- RULE 1: No Stack usage in Dashboard Body ---
    # Scope: lib/screens/dashboard/**
    # Exceptions: none initially
    
    stack_pattern = re.compile(r'Stack\(')
    
    if DASHBOARD_DIR.exists():
        for root, _, files in os.walk(DASHBOARD_DIR):
            for file in files:
                if not file.endswith(".dart"): continue
                
                path = Path(root) / file
                rel_path = path.relative_to(ROOT_DIR)
                
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        lines = f.readlines()
                        for i, line in enumerate(lines):
                            if stack_pattern.search(line):
                                violations.append({
                                    "rule": "NO_STACK_DASHBOARD",
                                    "file": str(rel_path),
                                    "line": i + 1,
                                    "code": line.strip(),
                                    "hint": "Use DashboardComposer and sequential layout instead of Stack. Stacks cause overlap (D38.01.1)."
                                })
                except Exception as e:
                    print(f"Error reading {rel_path}: {e}")

    # --- RULE 2: No EdgeInsets literals in Dashboard scope ---
    # Scope: lib/screens/dashboard/** + lib/screens/dashboard_screen.dart
    
    edge_insets_pattern = re.compile(r'EdgeInsets\.(all|only|symmetric|fromLTRB)\(')
    
    files_to_scan_for_spacing = []
    if DASHBOARD_DIR.exists():
         for root, _, files in os.walk(DASHBOARD_DIR):
            for file in files:
                if file.endswith(".dart"):
                    files_to_scan_for_spacing.append(Path(root) / file)
    
    if DASHBOARD_SCREEN_FILE.exists():
        files_to_scan_for_spacing.append(DASHBOARD_SCREEN_FILE)

    for path in files_to_scan_for_spacing:
        # SKIP the token file itself if it accidentally gets included (though it's in ui/tokens, not dashboard)
        if path.resolve() == SPACING_TOKENS_FILE.resolve():
            continue
            
        rel_path = path.relative_to(ROOT_DIR)
        
        try:
            with open(path, "r", encoding="utf-8") as f:
                lines = f.readlines()
                for i, line in enumerate(lines):
                    if edge_insets_pattern.search(line):
                         violations.append({
                            "rule": "NO_EDGEINSETS_LITERALS",
                            "file": str(rel_path),
                            "line": i + 1,
                            "code": line.strip(),
                            "hint": "Use DashboardSpacing tokens (e.g. DashboardSpacing.cardPadding) instead of hardcoded EdgeInsets."
                        })
        except Exception as e:
             print(f"Error reading {rel_path}: {e}")

    # --- RULE 3: Composer Required ---
    # Scope: DashboardScreen
    if DASHBOARD_SCREEN_FILE.exists():
        has_composer = False
        has_list_view = False
        
        try:
            with open(DASHBOARD_SCREEN_FILE, "r", encoding="utf-8") as f:
                content = f.read()
                if "DashboardComposer" in content:
                    has_composer = True
                if "ListView" in content or "CustomScrollView" in content or "SliverList" in content:
                    has_list_view = True
            
            if not has_composer:
                violations.append({
                    "rule": "COMPOSER_REQUIRED",
                    "file": str(DASHBOARD_SCREEN_FILE.relative_to(ROOT_DIR)),
                    "line": 0,
                    "code": "N/A",
                    "hint": "DashboardScreen must use DashboardComposer to orchestrate widgets."
                })
            
            if not has_list_view:
                 violations.append({
                    "rule": "LISTVIEW_REQUIRED",
                    "file": str(DASHBOARD_SCREEN_FILE.relative_to(ROOT_DIR)),
                    "line": 0,
                    "code": "N/A",
                    "hint": "DashboardScreen must use ListView/ScrollView to prevent unbounded height issues."
                })

        except Exception as e:
            print(f"Error reading {DASHBOARD_SCREEN_FILE}: {e}")
    else:
        print(f"WARNING: {DASHBOARD_SCREEN_FILE} not found. Cannot enforce Rule 3.")

    return violations

def scan_and_report():
    print("Running Dashboard Layout Discipline Verifier (D38.01.2)...")
    violations = scan_dashboard_layout()
    
    passed = len(violations) == 0
    
    report = {
        "status": "PASS" if passed else "FAIL",
        "violations": violations
    }
    
    if violations:
        print("\n[!] DASHBOARD LAYOUT VIOLATIONS FOUND:")
        for v in violations:
            print(f"  Rule: {v['rule']}")
            print(f"  File: {v['file']}:{v['line']}")
            print(f"  Code: {v['code']}")
            print(f"  >> HINT: {v['hint']}")
            print("-" * 40)
    else:
        print("[+] Dashboard Layout Discipline Verified. No forbidden patterns found.")
        
    return passed

if __name__ == "__main__":
    success = scan_and_report()
    if not success:
        sys.exit(1)
