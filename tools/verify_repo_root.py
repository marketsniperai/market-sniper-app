import os
import sys
import subprocess

def get_git_root():
    try:
        # Get the root of the git repo
        root = subprocess.check_output(['git', 'rev-parse', '--show-toplevel']).strip().decode('utf-8')
        return root
    except subprocess.CalledProcessError:
        return None

def get_remote_url():
    try:
        url = subprocess.check_output(['git', 'remote', 'get-url', 'origin']).strip().decode('utf-8')
        return url.lower()
    except subprocess.CalledProcessError:
        return None

def verify_identity():
    OFFICIAL_URL = "https://github.com/marketsniperai/market-sniper-app.git"
    
    # 1. Check Root
    root = get_git_root()
    if not root:
        print("ERROR: Not in a git repository.")
        sys.exit(1)
        
    # Check if we are in the mothership folder (optional naming check, but strict remote check is better)
    # 2. Check Remote
    url = get_remote_url()
    
    if url != OFFICIAL_URL.lower():
        # Allow for SSH variant or .git suffix variation if needed, but for now strict.
        # Check if it ends with market-sniper-app.git and has marketsniperai
        if "marketsniperai/market-sniper-app" in url:
             pass # Acceptable
        else:
             print(f"IDENTITY LOCK: FATAL MISMATCH.")
             print(f"Expected: {OFFICIAL_URL}")
             print(f"Found:    {url}")
             print("This is NOT the Official Mothership Repo. Operation Aborted.")
             sys.exit(1)

    print("IDENTITY CONFIRMED: Official Mothership Connection Active.")
    return True

if __name__ == "__main__":
    verify_identity()
