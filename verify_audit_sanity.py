
import sys
import os
sys.path.append(os.path.join(os.getcwd(), 'backend', 'os_ops'))
from d50_ewims_gold_runner import score_claim, build_index

def run_checks():
    print("--- EWIMS SANITY CHECKS ---")
    idx = build_index()
    
    # 1. War Room Endpoint
    c1 = {"sku": "TEST1", "desc": "War Room access via /lab/war_room endpoint"}
    s1, e1 = score_claim(c1, idx)
    print(f"1. War Room (/lab/war_room): Score={s1} (Expected >= 5) | {e1}")
    
    # 2. Iron OS Endpoint
    c2 = {"sku": "TEST2", "desc": "Iron OS Status at /lab/os/iron/status"}
    s2, e2 = score_claim(c2, idx)
    print(f"2. Iron OS (/lab/os/iron/status): Score={s2} (Expected >= 5) | {e2}")
    
    # 3. Fake Claim (Seal Only)
    # We simulate a claim that has NO tokens matching files, but might match a seal if we checked them (we don't here)
    # But score_claim doesn't verify seals. It checks index.
    c3 = {"sku": "FAKE1", "desc": "NonExistent Feature X"}
    s3, e3 = score_claim(c3, idx)
    print(f"3. Fake Claim: Score={s3} (Expected < 4) | {e3}")

    # 4. Check the 2 Ghosts
    c4 = {"sku": "D45.02", "desc": "Bottom Nav Hygiene + Persistence"}
    s4, e4 = score_claim(c4, idx)
    print(f"4. Ghost D45.02: Score={s4} | {e4}")
    
    c5 = {"sku": "MILESTONE", "desc": "Global Shell Persistence (Single Scaffold)"}
    s5, e5 = score_claim(c5, idx)
    print(f"5. Ghost Shell: Score={s5} | {e5}")

if __name__ == "__main__":
    run_checks()
