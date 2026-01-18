import os
import subprocess
import json
import fnmatch
from datetime import datetime, timezone
from pathlib import Path

# --- CONFIGURATION ---
REPO_ROOT = Path("c:/MSR/MarketSniperRepo").resolve()
REPORT_PATH = REPO_ROOT / "outputs/runtime/day_42/day_42_auto_stage_canon_report.json"

# ALLOWLIST: Must stage if modified/untracked
ALLOWLIST_PATTERNS = [
    "outputs/seals/*.md",
    "outputs/proofs/*.json",
    "docs/canon/OMSR_WAR_CALENDAR__35_45_DAYS.md",
    "PROJECT_STATE.md",
    "docs/canon/OS_MODULES.md",
    "os_registry.json"
]

# DENYLIST: Must NEVER stage (Hard Gate)
DENYLIST_PATTERNS = [
    "build/", ".dart_tool/", ".gradle/", ".idea/", ".vscode/", "node_modules/", "dist/", "out/",
    "*.apk", "*.aab",
    "*.keystore", "*.jks", "*.pem", "*.p12",
    "*.env", "*.env.*", "secrets/", "credentials", "tokens", "private keys",
    "*.log"
]

def run_git_cmd(args):
    result = subprocess.run(["git"] + args, cwd=REPO_ROOT, capture_output=True, text=True)
    return result.stdout.strip()

def matches_pattern(path_str, patterns):
    for pattern in patterns:
        # Directory pattern
        if pattern.endswith("/"):
            if pattern[:-1] in path_str.split("/"):
                return True, pattern
        # Glob pattern
        elif fnmatch.fnmatch(path_str, pattern):
            return True, pattern
            
        # Specific check for subdirectories in allowed paths (e.g. outputs/seals/foo.md)
        if pattern.endswith("*.md") and "/seals/" in path_str and path_str.endswith(".md"):
             return True, "outputs/seals/*.md"
        if pattern.endswith("*.json") and "/proofs/" in path_str and path_str.endswith(".json"):
             return True, "outputs/proofs/*.json"

    return False, None

def main():
    print("Starting Auto-Stage Canon Outputs...")
    
    # 1. Get Status
    status_output = run_git_cmd(["status", "--porcelain", "-uall"])
    
    # Parse porcelain output
    # ?? -> Untracked
    # M  -> Modified
    # A  -> Added (already staged)
    # etc.
    
    candidates = []
    lines = status_output.splitlines()
    
    for line in lines:
        if len(line) < 4: continue
        code = line[:2]
        path = line[3:].strip('"') # remove quotes if present
        
        # We care about Untracked (??) and Modified ( M, M , MM, AM, etc)
        # We do NOT care if it's already fully staged (A , M ) but usually we want to ensure latest modification is staged.
        # So we look at everything that isn't purely "deleted" or "ignored".
        
        candidates.append(path)

    staged = []
    skipped_denied = []
    remaining_untracked = []

    for fpath in candidates:
        raw_path = fpath.replace("\\", "/") # Normalize to forward slashes for matching
        
        # Check Denylist First
        is_denied, denied_pattern = matches_pattern(raw_path, DENYLIST_PATTERNS)
        if is_denied:
            skipped_denied.append({"path": fpath, "reason": f"Matches Denylist: {denied_pattern}"})
            continue
            
        # Check Allowlist
        is_allowed, allowed_pattern = matches_pattern(raw_path, ALLOWLIST_PATTERNS)
        
        if is_allowed:
            print(f"Staging: {fpath} (Matched: {allowed_pattern})")
            run_git_cmd(["add", fpath])
            staged.append(fpath)
        else:
            # If it's untracked (??) and not allowed, we must report it.
            # If it's modified (M) and not allowed, we leave it alone (user might be working on it).
            # We need to re-parse the specific line code for this file to know if it's untracked.
            # Simplified: Check if it's still untracked after this loop by running status again.
            pass

    # 2. Post-Stage Status
    final_status = run_git_cmd(["status", "--porcelain"])
    final_lines = final_status.splitlines()
    
    for line in final_lines:
        if line.startswith("?? "):
            path = line[3:].strip('"')
            remaining_untracked.append(path)

    # 3. Report
    report = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "status_before_porcelain": status_output,
        "staged_paths": staged,
        "skipped_denied_paths_with_reason": skipped_denied,
        "remaining_untracked_after": remaining_untracked,
        "status_after_porcelain": final_status
    }
    
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(REPORT_PATH, "w") as f:
        json.dump(report, f, indent=2)
        
    print(f"Report written to {REPORT_PATH}")
    
    if remaining_untracked:
        print("\n[WARNING] NON-CANON UNTRACKED FILES DETECTED (REVIEW REQUIRED):")
        for p in remaining_untracked:
            print(f"  - {p}")
        print("Do NOT claim step is sealed until resolved.\n")
    else:
        print("\n[SUCCESS] All canonical outputs staged. No untracked files remaining (or all ignored).")

if __name__ == "__main__":
    main()
