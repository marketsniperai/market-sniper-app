import os
import sys
import subprocess

def run_step(command):
    print(f"Running: {command}")
    try:
        subprocess.check_call(command, shell=True)
    except subprocess.CalledProcessError:
        print(f"ERROR: Command failed: {command}")
        sys.exit(1)

def check_git_status(paths):
    try:
        # Check if files are modified in working tree
        status = subprocess.check_output(['git', 'status', '--porcelain'] + paths).decode('utf-8').strip()
        if status:
            print("ERROR: Canonical artifacts are stale or modified:")
            print(status)
            print("Please commit the updated artifacts before pushing.")
            return False
        return True
    except subprocess.CalledProcessError:
        print("ERROR: Failed to check git status.")
        sys.exit(1)

def main():
    print("--- VERIFY CANON CLEAN ---")
    
    # 1. Regenerate Index
    run_step("py tools/build_seal_index.py")
    
    # 2. Regenerate Calendar
    run_step("py tools/compile_war_calendar.py")
    
    # 3. Check for uncommitted changes in generated files
    # We check if the regeneration caused any changes
    artifacts = [
        "outputs/audit/SEAL_INDEX.json",
        "docs/canon/OMSR_WAR_CALENDAR_AUTO.md"
    ]
    
    if not check_git_status(artifacts):
        sys.exit(1)
        
    print("SUCCESS: Canon is clean and synchronized.")

if __name__ == "__main__":
    main()
