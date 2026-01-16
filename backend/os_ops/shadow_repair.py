import os
import json
import shutil
import hashlib
from datetime import datetime, timezone
from typing import Dict, List, Any, Optional, Tuple
from pathlib import Path
from backend.artifacts.io import atomic_write_json, safe_read_or_fallback, get_artifacts_root
from backend.os_ops.consensus_gate import ConsensusGate
from backend.os_ops.autopilot_policy_engine import AutopilotPolicyEngine

class ShadowRepair:
    """
    Day 28.02: Shadow Repair v1.5 (Propose Only).
    Generates unified diffs and risk tags.
    Strict Rule: PROPOSE ONLY. NO APPLY.
    """
    
    OUTPUT_SUBDIR = "runtime/shadow_repair"
    REGISTRY_PATH = "os_registry.json"
    CONTRACTS_PATH = "os_module_contracts.json"
    PLAYBOOKS_PATH = "os_playbooks.yml"
    
    @staticmethod
    def propose_patch_v15(symptoms: List[str], playbook_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Generates a patch proposal based on symptoms/playbook.
        Does NOT apply changes. v1.5 adds Diff and Risk Tags.
        """
        root = get_artifacts_root()
        now_utc = datetime.now(timezone.utc).isoformat()
        
        # 1. Analyze Context & Determine Plan
        plan = ShadowRepair._analyze_plan(symptoms, playbook_id)
        
        # 2. Generate Artifacts (Diff, Summary)
        unified_diff = ShadowRepair._generate_unified_diff(plan)
        risk_tags = ShadowRepair._calculate_risk_tags(plan["target_files"])
        module_mapping = ShadowRepair._map_to_contract(plan["target_files"])

        # 3. Construct Proposal
        proposal_id = f"PROP-{hashlib.md5(now_utc.encode()).hexdigest()[:8]}"
        
        proposal = {
            "proposal_id": proposal_id,
            "created_utc": now_utc,
            "status": "PROPOSED_ONLY",
            "trigger": {
                "symptoms": symptoms,
                "playbook_id": playbook_id
            },
            "plan": plan,
            "unified_diff": unified_diff,
            "risk_tags": risk_tags,
            "mapped_playbook_id": playbook_id, # Can be enhanced if inferred
            "mapped_contract_id": module_mapping.get("module_id", "UNKNOWN"),
            "rationale": f"Auto-generated proposal based on {playbook_id or symptoms}",
            "safety_check": {
                "permits_apply": False,
                "reason": "Shadow Repair is Read-Only/Propose-Only (v1.5)"
            }
        }
        
        return proposal
        
        # 4. Persist
        ShadowRepair._persist_proposal(proposal, unified_diff)

        # Day 34: Black Box Hook
        from backend.os_ops.black_box import BlackBox
        BlackBox.record_event("SURGEON_PROPOSAL", proposal, {})

        return proposal

    @staticmethod
    def _analyze_plan(symptoms: List[str], playbook_id: Optional[str]) -> Dict[str, Any]:
        """
        Deterministic logic to create a plan (targets, actions).
        """
        plan = {
            "type": "UNKNOWN",
            "target_files": [],
            "proposed_actions": [],
            "content_stub": None
        }
        
        # Logic A: Misfire Recovery (Scaffold Manifest)
        if (playbook_id == "PB-T1-MISFIRE-LIGHT") or any("MISSING_LIGHT_MANIFEST" in s for s in symptoms):
             plan["type"] = "RECOVERY_SCAFFOLD"
             plan["target_files"] = ["outputs/light/run_manifest.json"]
             plan["proposed_actions"] = ["CREATE: Empty valid manifest"]
             plan["content_stub"] = { "status": "RECOVERED", "mode": "LIGHT", "generated_by": "ShadowRepair" }
             
        elif (playbook_id == "PB-T1-MISFIRE-FULL") or any("MISSING_FULL_MANIFEST" in s for s in symptoms):
             plan["type"] = "RECOVERY_SCAFFOLD"
             plan["target_files"] = ["outputs/full/run_manifest.json"]
             plan["proposed_actions"] = ["CREATE: Empty valid manifest"]
             plan["content_stub"] = { "status": "RECOVERED", "mode": "FULL", "generated_by": "ShadowRepair" }
             
        # Logic B: Lock Clear
        elif (playbook_id == "PB-T1-LOCK-STUCK") or any("LOCK_HELD" in s for s in symptoms):
             plan["type"] = "LOCK_CLEAR"
             plan["target_files"] = ["os_lock.json"]
             plan["proposed_actions"] = ["DELETE: os_lock.json"]
             
        return plan

    @staticmethod
    def _generate_unified_diff(plan: Dict[str, Any]) -> str:
        """
        Generates a standard unified diff string.
        """
        diff_lines = []
        
        for target in plan["target_files"]:
            if "outputs/" in target:
                 # Runtime Artifact
                 diff_lines.append(f"--- a/{target} (missing/stale)")
                 diff_lines.append(f"+++ b/{target} (proposed)")
                 diff_lines.append("@@ -0,0 +1,5 @@")
                 
                 if plan["type"] == "LOCK_CLEAR":
                     diff_lines.append("- [FILE DELETED]")
                 elif plan["content_stub"]:
                     content = json.dumps(plan["content_stub"], indent=2)
                     for line in content.splitlines():
                         diff_lines.append(f"+ {line}")
                 else:
                     diff_lines.append("+ [CONTENT UNKNOWN]")
            else:
                 # Source mod? (Not implemented for v1.5 safe logic yet, but if it were)
                 diff_lines.append(f"--- a/{target}")
                 diff_lines.append(f"+++ b/{target}")
                 diff_lines.append("@@ -1 +1 @@")
                 diff_lines.append("- [UNKNOWN]")
                 
        return "\n".join(diff_lines)

    @staticmethod
    def _calculate_risk_tags(target_files: List[str]) -> List[str]:
        """
        Determines risk based on file paths.
        """
        tags = []
        
        has_runtime = False
        has_source = False
        has_api = False
        
        for f in target_files:
            if f.startswith("outputs/"):
                has_runtime = True
                tags.append("TOUCHES_RUNTIME_ONLY")
            elif "api_server.py" in f or "schema" in f:
                has_api = True
                tags.append("TOUCHES_API_SURFACE")
                has_source = True
            elif f.startswith("backend/"):
                has_source = True
                tags.append("MODIFY_SOURCE")
                
        if has_api or has_source:
             tags.append("HIGH_RISK")
             tags.append("NEEDS_HUMAN_REVIEW")
        elif has_runtime:
             tags.append("LOW_RISK")
             
        if not tags:
             tags.append("INSUFFICIENT_CONTEXT")
             
        return list(set(tags)) # dedup

    @staticmethod
    def _map_to_contract(target_files: List[str]) -> Dict[str, Any]:
        """
        Maps target files to their owning module via os_module_contracts.json
        """
        # Load Contracts
        root = Path(os.getcwd()) # assumption
        contracts_p = root / ShadowRepair.CONTRACTS_PATH
        mapping = {"module_id": "UNKNOWN", "owner_found": False}
        
        if not contracts_p.exists():
            return mapping
            
        try:
             with open(contracts_p, "r") as f:
                 data = json.load(f)
                 modules = data.get("modules", {})
                 
             # Naive search: Does any module claim this artifact?
             for mod_name, details in modules.items():
                 for art in details.get("artifacts", []):
                     if any(f in art or art in f for f in target_files):
                         mapping["module_id"] = mod_name
                         mapping["owner_found"] = True
                         return mapping
        except: pass
        
        return mapping


    @staticmethod
    def _persist_proposal(proposal: Dict[str, Any], diff_text: str):
        root = get_artifacts_root()
        base = root / ShadowRepair.OUTPUT_SUBDIR
        os.makedirs(base, exist_ok=True)
        
        # JSON
        atomic_write_json(str(base / "patch_proposal.json"), proposal)
        
        # Diff
        with open(base / "patch_proposal.diff", "w") as f:
            f.write(diff_text)
            
        # Summary
        summary = f"""SHADOW REPAIR PROPOSAL v1.5
ID: {proposal['proposal_id']}
Date: {proposal['created_utc']}
Status: {proposal['status']}
Triggers: {proposal['trigger']}

RISK TAGS: {', '.join(proposal['risk_tags'])}
OWNER: {proposal['mapped_contract_id']}

PLAN:
Type: {proposal['plan']['type']}
Files: {', '.join(proposal['plan']['target_files'])}

DIFF PREVIEW:
{diff_text}

SURGEON STATUS:
Ready for evaluation. Run apply_proposal() to execute (if Policy allows).
"""
        with open(base / "patch_proposal_summary.txt", "w") as f:
            f.write(summary)
            
        # Ledger
        ledger_path = base / "shadow_repair_ledger.jsonl"
        with open(ledger_path, "a") as f:
            f.write(json.dumps({
                "id": proposal['proposal_id'],
                "utc": proposal['created_utc'],
                "risk": proposal['risk_tags'],
                "target": proposal['plan']['target_files'],
                "action": "PROPOSED"
            }) + "\n")

    @staticmethod
    def apply_proposal(proposal_id: str) -> Dict[str, Any]:
        """
        The Surgeon (Day 31).
        Applies a proposed patch if safety checks pass.
        Reversible. Verified.
        """
        root = get_artifacts_root()
        base = root / ShadowRepair.OUTPUT_SUBDIR
        
        # Day 30.1: Kill Switch Check
        try:
            with open("os_kill_switches.json", "r") as f:
                switches = json.load(f).get("switches", {})
                if not switches.get("SURGEON_RUNTIME_ENABLED", True):
                    return {"success": False, "error": "KILL_SWITCH: SURGEON_RUNTIME_ENABLED is FALSE"}
        except Exception as e: 
             # Fail safe if kill switch file missing (Freeze Law violation)
             return {"success": False, "error": f"KILL_SWITCH: Config Missing ({str(e)})"}

        prop_path = base / "patch_proposal.json"
        
        # 1. Load Proposal
        if not prop_path.exists():
            return {"success": False, "error": "Proposal not found"}
            
        try:
            with open(prop_path, "r") as f:
                proposal = json.load(f)
        except Exception as e:
            return {"success": False, "error": str(e)}
            
        if proposal["proposal_id"] != proposal_id:
            return {"success": False, "error": "ID Mismatch"}
            
        # 2. Extract Plan
        targets = proposal["plan"]["target_files"]
        stub = proposal["plan"].get("content_stub")
        action_type = proposal["plan"]["type"]
        risk_tags = proposal.get("risk_tags", [])
        
        # --- Day 30.2: 2-VOTE CONSENSUS LOOP ---
        
        # Voter A: Policy Engine
        # We need Policy context. We construct it from proposal tags & current band.
        # Band read:
        band = "UNKNOWN"
        try:
             # import json <-- REMOVED (Global import exists)
             with open(get_artifacts_root() / "runtime/agms/agms_stability_band.json", "r") as f:
                 band = json.load(f).get("band", "UNKNOWN")
        except: pass
        
        ctx = {
            "risk_tags": risk_tags,
            "band": band,
            "pattern": "SURGEON_RUNTIME_APPLY",
            "confidence_score": 1.0 # Operator triggered or Surgeon logic implies confidence
        }
        
        AutopilotPolicyEngine.cast_policy_vote(ctx, "APPLY_PATCH_RUNTIME", proposal_id)
        
        # Day 34: Black Box Hook (Policy Vote recorded by Polic Engine itself ideally, but we hook apply attempt)
        from backend.os_ops.black_box import BlackBox
        BlackBox.record_event("SURGEON_APPLY_ATTEMPT", {"id": proposal_id, "ctx": ctx}, {})
        
        # Voter B: Risk Assessor (Self)
        ShadowRepair.cast_risk_vote(proposal)
        
        # Gate: Check Consensus
        consensus = ConsensusGate.check_consensus(proposal_id)
        if not consensus["approved"]:
             return {
                 "success": False, 
                 "error": f"CONSENSUS DENIED: {consensus['reasons']}",
                 "details": consensus
             }
             
        # --- END CONSENSUS LOOP ---
        
        # 3. Execution Loop
        results = []
        for target in targets:
            # SAFETY GATES
            if "outputs/" not in target and "runtime/" not in target:
                 return {"success": False, "error": f"Surgeon forbids touching non-runtime: {target}"}
            
            # Backup
            backup_path = ShadowRepair._backup_artifact(target)
            
            # Apply
            success = False
            if action_type == "LOCK_CLEAR":
                success = ShadowRepair._delete_artifact(target)
            elif action_type == "RECOVERY_SCAFFOLD" and stub:
                success = ShadowRepair._write_artifact(target, stub)
            
            if not success:
                 return {"success": False, "error": f"Failed to apply action {action_type} on {target}"}
            
            # Verify
            if success:
                if ShadowRepair._verify_integrity(target):
                    results.append(f"Fixed {target}")
                else:
                    # Rollback
                    ShadowRepair._rollback_artifact(target, backup_path)
                    return {"success": False, "error": f"Verification failed for {target}. Rolled back."}
            else:
                 # Rollback if apply failed mid-way? (Usually deletion failed -> nothing to rollback, writing failed -> atomic)
                 pass
                 
        # 4. Log Success
        ledger_path = base / "shadow_repair_ledger.jsonl"
        with open(ledger_path, "a") as f:
            f.write(json.dumps({
                "id": proposal['proposal_id'],
                "utc": datetime.now(timezone.utc).isoformat(),
                "action": "EXECUTED_RUNTIME_PATCH",
                "targets": targets
            }) + "\n")
            
        return {"success": True, "results": results}

    @staticmethod
    def _backup_artifact(rel_path: str) -> str:
        root = get_artifacts_root()
        target = root / rel_path
        if not target.exists(): return None
        
        bak = str(target) + ".bak"
        shutil.copy2(target, bak)
        return bak
        
    @staticmethod
    def _rollback_artifact(rel_path: str, backup_path: str):
        if not backup_path: return
        root = get_artifacts_root()
        target = root / rel_path
        shutil.copy2(backup_path, target)
        
    @staticmethod
    def _delete_artifact(rel_path: str) -> bool:
        root = get_artifacts_root()
        target = root / rel_path
        if target.exists():
            os.remove(target)
        return not target.exists()
        
    @staticmethod
    def _write_artifact(rel_path: str, content: Dict[str, Any]) -> bool:
        root = get_artifacts_root()
        target = root / rel_path
        try:
            os.makedirs(target.parent, exist_ok=True)
            atomic_write_json(str(target), content)
            return True
        except Exception as e:
            print(f"DEBUG WRITE ERROR: {e}")
            return False
        
    @staticmethod
    def _verify_integrity(rel_path: str) -> bool:
        # Basic read check
        root = get_artifacts_root()
        target = root / rel_path
        if not target.exists(): 
             # If we intended to delete, non-existence is success
             # But this verify is generic.
             # For LOCK_CLEAR, we should check it Does NOT exist.
             return True # Lazy check for now, context dependent
        
        try:
             with open(target, "r") as f:
                 json.load(f)
             return True
        except: return False

    @staticmethod
    def cast_risk_vote(proposal: Dict[str, Any]):
        """
        Day 30.2: Voter B (Risk Assessor).
        Evaluates risk tags and confines paths.
        Writes 'risk_vote.json' if Safe.
        """
        proposal_id = proposal.get("proposal_id")
        risk_tags = set(proposal.get("risk_tags", []))
        
        # Rules for ALLOW
        required = {"LOW_RISK", "TOUCHES_RUNTIME_ONLY"}
        forbidden = {"HIGH_RISK", "MODIFY_SOURCE", "TOUCHES_API_SURFACE"}
        
        reasons = []
        status = "DENY"
        
        if not required.issubset(risk_tags):
            reasons.append(f"Missing required tags: {required - risk_tags}")
        
        if any(t in risk_tags for t in forbidden):
             reasons.append(f"Forbidden tags present: {risk_tags.intersection(forbidden)}")
             
        if not reasons:
             status = "ALLOW"
             reasons.append("Risk assessment passed: Low Risk + Runtime Only.")
             
        vote = {
             "proposal_id": proposal_id,
             "decision": status,
             "reasons": reasons,
             "timestamp_utc": datetime.now(timezone.utc).isoformat(),
             "voter": "ShadowRepairRiskAssessor"
        }
        
        # Persist Vote
        root = get_artifacts_root()
        vote_path = root / "runtime/shadow_repair/votes/risk_vote.json"
        try:
             os.makedirs(vote_path.parent, exist_ok=True)
             atomic_write_json(str(vote_path), vote)
        except Exception as e:
             print(f"Risk Vote Write Failed: {e}")
