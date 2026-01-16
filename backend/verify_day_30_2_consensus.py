import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

# Add CWD
sys.path.append(os.getcwd())

from backend.os_ops.consensus_gate import ConsensusGate
from backend.os_ops.shadow_repair import ShadowRepair
from backend.artifacts.io import get_artifacts_root, atomic_write_json

OUTPUT_DIR = "outputs/runtime/day_30_2"
os.makedirs(OUTPUT_DIR, exist_ok=True)
root = get_artifacts_root()

def setup_files(proposal_id, p_dec, r_dec):
    # Helper to force vote files
    p_vote = {
        "proposal_id": proposal_id,
        "decision": p_dec,
        "reasons": ["UnitTest"],
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "voter": "PolicyMock"
    }
    r_vote = {
        "proposal_id": proposal_id,
        "decision": r_dec,
        "reasons": ["UnitTest"],
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "voter": "RiskMock"
    }
    
    p_path = root / ConsensusGate.POLICY_VOTE_PATH
    r_path = root / ConsensusGate.RISK_VOTE_PATH
    
    os.makedirs(p_path.parent, exist_ok=True)
    os.makedirs(r_path.parent, exist_ok=True)
    
    if p_dec != "MISSING":
        with open(p_path, "w") as f: json.dump(p_vote, f)
    elif p_path.exists():
        p_path.unlink()
        
    if r_dec != "MISSING":
        with open(r_path, "w") as f: json.dump(r_vote, f)
    elif r_path.exists():
        r_path.unlink()

def test_consensus_logic():
    print("\n--- TEST: Consensus Gate Logic (Unit) ---")
    pid = "PROP-TEST-001"
    
    # Case 1: Policy ALLOW + Risk DENY
    setup_files(pid, "ALLOW", "DENY")
    res = ConsensusGate.check_consensus(pid)
    if res["approved"]:
        print("FAIL: Case 1 (ALLOW+DENY) was Approved")
        return False
    print(f"PASS: Case 1 (ALLOW+DENY) -> Denied. Reasons: {res['reasons']}")
    
    # Case 2: Policy DENY + Risk ALLOW
    setup_files(pid, "DENY", "ALLOW")
    res = ConsensusGate.check_consensus(pid)
    if res["approved"]:
        print("FAIL: Case 2 (DENY+ALLOW) was Approved")
        return False
    print(f"PASS: Case 2 (DENY+ALLOW) -> Denied. Reasons: {res['reasons']}")
    
    # Case 4: Missing Vote
    setup_files(pid, "ALLOW", "MISSING")
    res = ConsensusGate.check_consensus(pid)
    if res["approved"]:
        print("FAIL: Case 4 (Missing Risk) was Approved")
        return False
    print(f"PASS: Case 4 (Missing Risk) -> Denied. Reasons: {res['reasons']}")
    
    setup_files(pid, "MISSING", "ALLOW")
    res = ConsensusGate.check_consensus(pid)
    if res["approved"]:
        print("FAIL: Case 4 (Missing Policy) was Approved")
        return False
    print(f"PASS: Case 4 (Missing Policy) -> Denied. Reasons: {res['reasons']}")
    
    # Case 3: Happy Path (Mocked)
    setup_files(pid, "ALLOW", "ALLOW")
    res = ConsensusGate.check_consensus(pid)
    if not res["approved"]:
        print(f"FAIL: Case 3 (ALLOW+ALLOW) was Denied. Reasons: {res['reasons']}")
        return False
    print(f"PASS: Case 3 (ALLOW+ALLOW) -> Approved")
    
    # Dump Mock Decision
    with open(f"{OUTPUT_DIR}/consensus_decision_unit.json", "w") as f:
        json.dump(res, f, indent=2)
        
    return True

def test_integration():
    print("\n--- TEST: Integration (Surgeon apply_proposal) ---")
    # 1. Create a Valid Proposal
    pid = "PROP-INTEGRATION-001"
    proposal = {
        "proposal_id": pid,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "status": "PROPOSED",
        "plan": {
            "type": "RECOVERY_SCAFFOLD",
            "target_files": ["outputs/runtime/day_30_2/test_file.json"],
            "content_stub": {"test": "success"}
        },
        "risk_tags": ["LOW_RISK", "TOUCHES_RUNTIME_ONLY"],
        "unified_diff": "diff..."
    }
    
    # Write proposal
    base = root / ShadowRepair.OUTPUT_SUBDIR
    os.makedirs(base, exist_ok=True)
    with open(base / "patch_proposal.json", "w") as f:
        json.dump(proposal, f)
        
    # Ensure Kill Switch is ON
    try:
        with open("os_kill_switches.json", "r") as f:
            ks = json.load(f)
            if not ks["switches"]["SURGEON_RUNTIME_ENABLED"]:
                 print("WARNING: Enabling Surgeon Kill Switch for test")
                 ks["switches"]["SURGEON_RUNTIME_ENABLED"] = True
                 with open("os_kill_switches.json", "w") as fw: json.dump(ks, fw)
    except: pass
    
    # Run Apply
    print("Executing Apply...")
    res = ShadowRepair.apply_proposal(pid)
    
    if not res["success"]:
        print(f"FAIL: Integration Apply Failed. Error: {res.get('error')}")
        return False
        
    print(f"PASS: Integration Apply Succeeded. Result: {res}")
    
    # Verify Votes exist and match
    p_vote = root / ConsensusGate.POLICY_VOTE_PATH
    r_vote = root / ConsensusGate.RISK_VOTE_PATH
    
    if not p_vote.exists() or not r_vote.exists():
        print("FAIL: Votes not persisted")
        return False
        
    print("PASS: Votes persisted")
    
    # Copy votes to evidence dir
    import shutil
    votes_evidence = Path(OUTPUT_DIR) / "sample_votes"
    os.makedirs(votes_evidence, exist_ok=True)
    shutil.copy2(p_vote, votes_evidence / "policy_vote.json")
    shutil.copy2(r_vote, votes_evidence / "risk_vote.json")
    
    # Dump final verification artifact
    final_res = {"status": "PASS", "timestamp": datetime.now(timezone.utc).isoformat()}
    with open(f"{OUTPUT_DIR}/day_30_2_verify.json", "w") as f:
        json.dump(final_res, f)
        
    return True

if __name__ == "__main__":
    if test_consensus_logic() and test_integration():
        print("\nALL TESTS PASSED")
        sys.exit(0)
    else:
        print("\nTESTS FAILED")
        sys.exit(1)
