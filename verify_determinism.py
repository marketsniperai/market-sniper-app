
import os
import hashlib
import time
import shutil

# Change to repo root
os.chdir(r"c:\MSR\MarketSniperRepo")

def compute_hashes():
    files = [
        "outputs/audits/D50_EWIMS_FINAL_VERDICT.md",
        "outputs/audits/D50_EWIMS_GHOST_ZOMBIE_LIST.md",
        "outputs/audits/D50_EWIMS_TRACE.json"
    ]
    hashes = {}
    for f in files:
        if os.path.exists(f):
            with open(f, "rb") as file:
                hashes[f] = hashlib.sha256(file.read()).hexdigest()
        else:
            hashes[f] = "MISSING"
    return hashes

print("--- RUN 1 ---")
os.system("py backend/os_ops/d50_ewims_gold_runner.py")
hashes1 = compute_hashes()

print("\n--- RUN 2 ---")
os.system("py backend/os_ops/d50_ewims_gold_runner.py")
hashes2 = compute_hashes()

print("\n--- COMPARISON ---")
match = True
for f in hashes1:
    h1 = hashes1[f]
    h2 = hashes2[f]
    print(f"File: {f}")
    print(f"  Run 1: {h1}")
    print(f"  Run 2: {h2}")
    if h1 != h2:
        print("  MISMATCH!")
        match = False
    else:
        print("  MATCH")

if match:
    print("\nSUCCESS: Audit is deterministic.")
    
    # Check if D45.02 is ALIVE
    if "D45.02" in open("outputs/audits/D50_EWIMS_GHOST_ZOMBIE_LIST.md").read():
        print("WARNING: D45.02 is STILL a GHOST!")
    else:
        print("SUCCESS: D45.02 is ALIVE (Wiring Detected).")
else:
    print("\nFAILURE: Audit is non-deterministic.")
