#!/usr/bin/env python3
import os
import sys
import subprocess
from pathlib import Path

def normalize_path(path_str):
    return StringPath(os.path.abspath(path_str)).resolve()

def get_git_toplevel():
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True
        )
        return Path(result.stdout.strip()).resolve()
    except subprocess.CalledProcessError:
        print("ERROR: Not in a git repository.")
        sys.exit(1)

def main():
    cwd = Path.cwd().resolve()
    git_root = get_git_toplevel()

    if cwd != git_root:
        print("\n[ROOT-ANCHORED DOCTRINE VIOLATION]")
        print(f"Current Working Directory: {cwd}")
        print(f"Git Toplevel Root:       {git_root}")
        print("\nFATAL: Execution MUST utilize the repository root as the anchor.")
        print(f"Fix: cd {git_root}")
        sys.exit(1)
    
    print(f"[PASS] Root-Anchored: {cwd}")
    sys.exit(0)

if __name__ == "__main__":
    main()
