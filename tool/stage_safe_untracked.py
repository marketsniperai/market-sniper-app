import os
import subprocess
import json
from datetime import datetime, timezone
from pathlib import Path

# --- CONFIGURATION ---
REPO_ROOT = Path("c:/MSR/MarketSniperRepo").resolve()
PROOF_PATH = REPO_ROOT / "outputs/runtime/day_42/day_42_git_stage_untracked_proof.json"
EXCLUDE_PATTERNS = [
    "build/", ".dart_tool/", ".gradle/", ".idea/", ".vscode/", "node_modules/",
    "dist/", "out/", "outputs/runtime/", "*.apk", "*.aab", "*.keystore", "*.jks",
    "*.pem", "*.p12", "*.env", ".env", "secrets/", "token", "key", "credentials", "*.log"
]
# Allow specific proof file even if in outputs/runtime
ALLOW_PROOF_FILE = "day_42_git_stage_untracked_proof.json"
MAX_SIZE_MB = 10

def is_safe(path_str):
    # Check exclusions
    for pattern in EXCLUDE_PATTERNS:
        # Simple glob-like check (startswith/endswith/contains)
        # For directory patterns like "build/"
        if pattern.endswith("/"):
            if pattern[:-1] in path_str.split(os.sep): return False, f"Matches {pattern}"
        # For extensions
        elif pattern.startswith("*."):
            ext = pattern[1:]
            if path_str.endswith(ext): return False, f"Extension {ext}"
        # For keywords
        elif pattern in path_str:
             # Special case: allow the proof file we are about to create (if it appears untracked already)
             if ALLOW_PROOF_FILE in path_str:
                 return True, "Allowed Proof File"
             return False, f"Contains forbidden keyword {pattern}"
    
    # Check size
    try:
        size_mb = os.path.getsize(path_str) / (1024 * 1024)
        if size_mb > MAX_SIZE_MB:
            return False, f"Size {size_mb:.2f}MB > {MAX_SIZE_MB}MB"
    except OSError:
        return False, "Attributes unreadable"

    return True, "Safe"

def run_git_cmd(args):
    result = subprocess.run(["git"] + args, cwd=REPO_ROOT, capture_output=True, text=True)
    return result.stdout.strip()

def main():
    print("Starting Safe Staging...")
    
    # 1. Get Status
    status_output = run_git_cmd(["status", "--porcelain"])
    untracked_lines = [line for line in status_output.splitlines() if line.startswith("?? ")]
    
    untracked_files = [line[3:].strip('"') for line in untracked_lines] # removed quotes if present
    
    print(f"Found {len(untracked_files)} untracked files.")
    
    staged = []
    skipped = []
    
    # 2. Filter & Stage
    for fpath in untracked_files:
        full_path = REPO_ROOT / fpath
        if not full_path.exists():
            skipped.append({"path": fpath, "reason": "Not found (deleted?)"})
            continue
            
        safe, reason = is_safe(str(fpath).replace("\\", "/"))
        
        if safe:
            print(f"Staging: {fpath}")
            run_git_cmd(["add", fpath])
            staged.append(fpath)
        else:
            print(f"Skipping: {fpath} ({reason})")
            skipped.append({"path": fpath, "reason": reason})

    # 3. Final Status
    final_status = run_git_cmd(["status", "--porcelain"])
    
    # 4. Generate Proof
    proof = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "repo_root": str(REPO_ROOT),
        "untracked_found_count": len(untracked_files),
        "staged_count": len(staged),
        "staged_paths": staged,
        "skipped_count": len(skipped),
        "skipped_paths_with_reason": skipped,
        "final_git_status_porcelain": final_status
    }
    
    PROOF_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(PROOF_PATH, "w") as f:
        json.dump(proof, f, indent=2)
        
    print(f"Proof written to {PROOF_PATH}")

if __name__ == "__main__":
    main()
