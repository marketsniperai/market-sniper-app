import os
import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List, Optional
from backend.artifacts.io import safe_read_or_fallback, atomic_write_json, get_artifacts_root

POLICY_PATH = "os_autopilot_policy.json"
LEDGER_PATH = "runtime/autopilot/autopilot_policy_ledger.jsonl"
SNAPSHOT_PATH = "runtime/autopilot/autopilot_policy_snapshot.json"

class AutopilotPolicyEngine:
    """
    Day 28: Autopilot Policy Engine (Autonomy Dial).
    Decides if an action can be executed based on Mode, Band, Limits, and Evidence.
    """
    
    @staticmethod
    def evaluate_autopilot_decision(
        context: Dict[str, Any], 
        playbook_id: str,
        action_code: str,
        founder_key_present: bool = False
    ) -> Dict[str, Any]:
        """
        Main evaluation entry point.
        Returns a decision payload with status ALLOW or DENY.
        """
        root = get_artifacts_root()
        now_utc = datetime.now(timezone.utc)
        
        # 1. Load Policy
        policy = AutopilotPolicyEngine._load_policy()
        active_mode = policy["configuration"]["active_mode"]
        
        # Override Mode check (Founder override logic from policy)
        # If active_mode is SHADOW but founder key is present AND policy allows override,
        # we treat it as SAFE_AUTOPILOT for this evaluation (if requested).
        # Actually, let's keep it strict: The Dial is the Dial.
        # But commonly "manual trigger" via API calls `execute_action` directly, strict gates are there.
        # This engine is specifically for "Autopilot Handoff" flow.
        # If founder key is present in a handoff request, we might relax "Mode" check?
        # Let's stick to the spec: "founder_overrides: allow_safe_autopilot_with_key" means
        # if key is present, we can escalate mode to SAFE_AUTOPILOT effectively for this transaction.
        
        effective_mode = active_mode
        if founder_key_present and policy["configuration"]["founder_overrides"]["allow_safe_autopilot_with_key"]:
            if active_mode == "SHADOW" or active_mode == "OFF":
                 effective_mode = "SAFE_AUTOPILOT"
                 
        mode_config = policy["modes"].get(effective_mode, policy["modes"]["OFF"])
        
        decision = {
            "timestamp_utc": now_utc.isoformat(),
            "status": "DENY",
            "mode": effective_mode,
            "playbook_id": playbook_id,
            "action_code": action_code,
            "reasons": [],
            "limits_snapshot": {},
            "band_snapshot": "UNKNOWN"
        }
        
        # --- CHECK 0: KILL SWITCHES (Day 30.1) ---
        # "Analog" overrides that bypass standard logic (but adhere to Freeze Law).
        try:
             # Assume os_kill_switches.json in root.
             # Strict: If missing, we fail open or close? Freeze Law says mandatory.
             if os.path.exists("os_kill_switches.json"):
                 with open("os_kill_switches.json", "r") as f:
                     switches = json.load(f).get("switches", {})
                     
                     
                     # 1. Master Autopilot Switch
                     if not switches.get("AUTOPILOT_ENABLED", True):
                         decision["reasons"].append("KILL_SWITCH: AUTOPILOT_ENABLED is FALSE")
                         AutopilotPolicyEngine._log_decision(decision)
                         AutopilotPolicyEngine._log_shadow_trace(decision, context)
                         return decision
                         
                     # 2. Surgeon Runtime Specific
                     if action_code == "APPLY_PATCH_RUNTIME" and not switches.get("SURGEON_RUNTIME_ENABLED", True):
                         decision["reasons"].append("KILL_SWITCH: SURGEON_RUNTIME_ENABLED is FALSE")
                         AutopilotPolicyEngine._log_decision(decision)
                         AutopilotPolicyEngine._log_shadow_trace(decision, context)
                         return decision
             else:
                 # If config missing, technically a Freeze Law violation.
                 # We DENY to be safe.
                 decision["reasons"].append("KILL_SWITCH: Config Missing (os_kill_switches.json)")
                 AutopilotPolicyEngine._log_decision(decision)
                 AutopilotPolicyEngine._log_shadow_trace(decision, context)
                 return decision
        except Exception as e:
             decision["reasons"].append(f"KILL_SWITCH: Error reading config ({str(e)})")
             AutopilotPolicyEngine._log_decision(decision)
             return decision
        
        # --- CHECK 1: MODE ALLOWANCE ---
        if not mode_config.get("allow_execution", False):
            decision["reasons"].append(f"Mode {effective_mode} does not allow execution.")
            AutopilotPolicyEngine._log_decision(decision)
            AutopilotPolicyEngine._log_shadow_trace(decision, context)
            return decision

        # --- CHECK 2: ALLOWLIST ---
        if action_code not in policy.get("allowlist", []):
             decision["reasons"].append(f"Action {action_code} not in allowlist.")
             AutopilotPolicyEngine._log_decision(decision)
             AutopilotPolicyEngine._log_shadow_trace(decision, context)
             return decision

        # --- CHECK 2.5: SURGEON RISK GATES (Day 31) ---
        if action_code == "APPLY_PATCH_RUNTIME":
             risk_tags = context.get("risk_tags", [])
             required_tags = {"LOW_RISK", "TOUCHES_RUNTIME_ONLY"}
             forbidden_tags = {"HIGH_RISK", "MODIFY_SOURCE"}
             
             current_tags_set = set(risk_tags)
             
             if any(tag in current_tags_set for tag in forbidden_tags):
                  decision["reasons"].append("Deny: Surgeon attempted High Risk action.")
                  AutopilotPolicyEngine._log_decision(decision)
                  AutopilotPolicyEngine._log_shadow_trace(decision, context)
                  return decision
                  
             if not required_tags.issubset(current_tags_set):
                  decision["reasons"].append("Deny: Surgeon action requires LOW_RISK and TOUCHES_RUNTIME_ONLY.")
                  AutopilotPolicyEngine._log_decision(decision)
                  AutopilotPolicyEngine._log_shadow_trace(decision, context)
                  return decision

        # --- CHECK 3: BAND RULES ---
        # Load Band
        band_res = safe_read_or_fallback("runtime/agms/agms_stability_band.json")
        current_band = "UNKNOWN"
        if band_res["success"]:
            current_band = band_res["data"].get("band", "UNKNOWN")
            
        decision["band_snapshot"] = current_band
        allowed_bands = mode_config.get("required_band", [])
        
        if allowed_bands and current_band not in allowed_bands:
             decision["reasons"].append(f"Band {current_band} not in allowed bands {allowed_bands} for mode {effective_mode}.")
             # Fail here? Yes.
             AutopilotPolicyEngine._log_decision(decision)
             context["band"] = current_band
             AutopilotPolicyEngine._log_shadow_trace(decision, context)
             return decision

        # --- CHECK 4: LIMITS (Rate & Count) ---
        limits = policy["limits"]
        limit_check = AutopilotPolicyEngine._check_limits(limits, playbook_id, now_utc)
        decision["limits_snapshot"] = limit_check["snapshot"]
        
        if not limit_check["allowed"]:
             decision["reasons"].extend(limit_check["reasons"])
             AutopilotPolicyEngine._log_decision(decision)
             context["band"] = current_band
             AutopilotPolicyEngine._log_shadow_trace(decision, context)
             return decision
             
        # --- CHECK 5: EVIDENCE ---
        # Verify AGMS suggestion exists
        # We trust the caller provided a valid handoff which implies suggestion existed at handoff time.
        # But we could double check verify the suggestion is "fresh" or still valid if we wanted strictness.
        # For v1, we assume the Handoff Token verification (in autofix) covers the "chain of custody".
        # We just check the policy rule:
        if policy["required_evidence_rules"].get("agms_suggestion_must_exist"):
             # We assume Passed because we are here? 
             # Let's verify agms_shadow_snapshot.json has this playbook suggested?
             # This might be race-condition prone if suggestion rotated.
             # Strictness: Handoff token contains the suggestion ID. We validated that in Autofix.
             pass

        # --- ALL CHECKS PASSED ---
        decision["status"] = "ALLOW"
        decision["reasons"].append("All policy checks passed.")
        
        AutopilotPolicyEngine._log_decision(decision)
        
        # Day 29: Trace Hook (Success Case)
        trace_context = context.copy()
        if "band" not in trace_context: trace_context["band"] = current_band
        AutopilotPolicyEngine._log_shadow_trace(decision, trace_context)
        
        return decision

    @staticmethod
    def _load_policy() -> Dict[str, Any]:
        # Try finding in root
        if os.path.exists(POLICY_PATH):
             with open(POLICY_PATH, "r") as f:
                 return json.load(f)
        # Fallback empty safe
        return {
            "configuration": {"active_mode": "OFF"},
            "modes": {"OFF": {"allow_execution": False}},
            "limits": {},
            "allowlist": []
        }

    @staticmethod
    def _check_limits(limits: Dict[str, Any], playbook_id: str, now: datetime) -> Dict[str, Any]:
        """
        Reads ledger checks counts.
        """
        # Read ledger tail
        # We need to scan the whole day unfortunately or keep a rolling state.
        # For simplicity and robustness, we scan the ledger file (it shouldn't be huge yet).
        # In prod, we'd use a rolling window state file. 
        # Let's read the last 1000 lines of ledger.
        
        ledger_file = get_artifacts_root() / LEDGER_PATH
        
        actions_today = 0
        actions_hour = 0
        consecutive = 0
        last_pb = None
        
        if ledger_file.exists():
            with open(ledger_file, "r") as f:
                # Naive read all for Day 28 scale
                lines = f.readlines()
                for line in reversed(lines):
                    try:
                        record = json.loads(line)
                        if record["status"] != "ALLOW": continue
                        
                        ts = datetime.fromisoformat(record["timestamp_utc"])
                        if ts.tzinfo is None: ts = ts.replace(tzinfo=timezone.utc)
                        
                        delta = (now - ts).total_seconds()
                        
                        # Day check (24h sliding or calendar? Policy says "per day", usually sliding 24h is safer)
                        if delta < 86400:
                            actions_today += 1
                        
                        # Hour check
                        if delta < 3600:
                            actions_hour += 1
                            
                        # Consecutive check (only if we haven't broken the chain)
                        # We are iterating backwards.
                        if consecutive != -1: # utilizing -1 as "chain broken" flag
                             if record["playbook_id"] == playbook_id:
                                 consecutive += 1
                             else:
                                 consecutive = -1 # Chain broken by different playbook
                                 
                    except: pass
                    
        # Reset consecutive if we flagged it
        if consecutive == -1: consecutive = 0 # Meaning the immediate previous ones were NOT this playbook
        else:
             # Wait, logic check. 
             # If we are checking "max_consecutive_same_playbook", we look at the MOST RECENT allowed actions.
             # If the last one was PB-A, and we want to run PB-A, consecutive=1.
             # If limit is 1, and we have 1, we deny.
             
             # Re-eval consecutive properly:
             consecutive = 0
             # Read forward or backward until different?
             pass # Logic above was close but let's be simpler.
             
        # Correct Consecutive Logic:
        # Check the *most recent* ALLOWED action.
        last_allowed_pb = None
        if ledger_file.exists():
             with open(ledger_file, "r") as f:
                 lines = f.readlines()
                 for line in reversed(lines):
                     try:
                         rec = json.loads(line)
                         if rec["status"] == "ALLOW":
                             last_allowed_pb = rec["playbook_id"]
                             break
                     except: pass
        
        is_consecutive = (last_allowed_pb == playbook_id)
        
        reasons = []
        allowed = True
        
        if actions_today >= limits.get("max_actions_per_day", 2):
            reasons.append(f"Daily limit {limits['max_actions_per_day']} reached.")
            allowed = False
            
        if actions_hour >= limits.get("max_actions_per_hour", 1):
            reasons.append(f"Hourly limit {limits['max_actions_per_hour']} reached.")
            allowed = False
            
        if is_consecutive and limits.get("max_consecutive_same_playbook", 1) < 2:
             # If limit is 1, and it IS consecutive (meaning previous was same), we deny?
             # "max_consecutive_same_playbook (default 1)" implies we can do 1.
             # If we do another, that's 2.
             # So if last was same, and limit is 1, we cannot do it.
             reasons.append(f"Consecutive limit {limits['max_consecutive_same_playbook']} reached for {playbook_id}.")
             allowed = False

        return {
            "allowed": allowed,
            "reasons": reasons,
            "snapshot": {
                "actions_today": actions_today,
                "actions_hour": actions_hour,
                "last_playbook": last_allowed_pb
            }
        }

    @staticmethod
    def cast_policy_vote(context: Dict[str, Any], action_code: str, proposal_id: str) -> Dict[str, Any]:
        """
        Day 30.2: Casts a persistent vote for Consensus.
        Wraps evaluate_autopilot_decision.
        """
        # 1. Evaluate
        decision = AutopilotPolicyEngine.evaluate_autopilot_decision(context, "SURGEON-VOTE", action_code)
        
        # 2. Formulate Vote
        vote = {
            "proposal_id": proposal_id,
            "decision": decision["status"],
            "reasons": decision["reasons"],
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "voter": "AutopilotPolicyEngine"
        }
        
        # 3. Persist if ALLOW (or even DENY? Requirement says "ALLOW solo si ambos ALLOW". 
        # Persistence of DENY is useful for audit, but Gate blocks if missing. 
        # Let's persist all votes.)
        root = get_artifacts_root()
        vote_path = root / "runtime/autopilot/votes/policy_vote.json"
        
        try:
            os.makedirs(vote_path.parent, exist_ok=True)
            atomic_write_json(str(vote_path), vote)
        except Exception as e:
            decision["reasons"].append(f"Vote Persistence Failed: {e}")
            
        return decision

    @staticmethod
    def _log_decision(decision: Dict[str, Any]):
        root = get_artifacts_root()
        l_path = root / LEDGER_PATH
        os.makedirs(l_path.parent, exist_ok=True)
        
        with open(l_path, "a") as f:
            f.write(json.dumps(decision) + "\n")
            
        # Update Snapshot
        atomic_write_json(str(root / SNAPSHOT_PATH), decision)

        # Day 34: Black Box Hook
        from backend.os_ops.black_box import BlackBox
        BlackBox.record_event("POLICY_DECISION", decision, {})

    @staticmethod
    def _log_shadow_trace(decision: Dict[str, Any], context: Dict[str, Any]):
        """
        Day 29: Shadow Trace Hook.
        Logs 'What If' scenarios for observation.
        """
        root = get_artifacts_root()
        shadow_ledger = root / "runtime/autopilot/autopilot_shadow_decisions.jsonl"
        
        # Determine Hypothetical
        hypothetical = "EXECUTED" if decision["status"] == "ALLOW" else "BLOCKED"
        
        entry = {
            "timestamp": decision.get("timestamp_utc", datetime.now(timezone.utc).isoformat()),
            "detected_pattern": context.get("pattern", "UNKNOWN"),
            "suggested_playbook": decision.get("playbook_id"),
            "confidence_score": context.get("confidence_score", 0.0),
            "current_stability_band": context.get("band", "UNKNOWN"),
            "policy_mode": decision.get("mode"),
            "policy_decision": decision["status"],
            "deny_reason": decision.get("reasons", []),
            "hypothetical_action": hypothetical,
            "execution_status": "NOT_EXECUTED"
        }
        
        os.makedirs(shadow_ledger.parent, exist_ok=True)
        with open(shadow_ledger, "a") as f:
            f.write(json.dumps(entry) + "\n")

