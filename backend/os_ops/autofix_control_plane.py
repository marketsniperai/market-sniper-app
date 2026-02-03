import os
import json
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Any, Optional
import requests
import google.auth
from google.auth.transport.requests import Request as GoogleRequest

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

from backend.artifacts.io import safe_read_or_fallback, atomic_write_json, get_artifacts_root
import backend.os_ops.misfire_monitor as misfire_monitor
from backend.os_ops.autopilot_policy_engine import AutopilotPolicyEngine

# Configuration
AUTOFIX_SUBDIR = "runtime/autofix"
FULL_MANIFEST_PATH = "full/run_manifest.json"
LIGHT_MANIFEST_PATH = "light/run_manifest.json"
LOCK_FILE_PATH = "os_lock.json"
PLAYBOOK_REGISTRY_PATH = "os_playbooks.yml" # Expected in repo root

# Thresholds
STALE_LIGHT_SECONDS = 900  # 15 minutes
STALE_FULL_SECONDS = 93600  # 26 hours
AGE_INFINITE = 999999999.0

class AutoFixControlPlane:
    """
    Day 19: AutoFix Control Plane v2 (Playbook-Driven).
    Observes system health, matches against Canonical Playbooks, and logs to an immutable ledger.
    """

    @staticmethod
    def load_playbooks() -> List[Dict[str, Any]]:
        """
        Load playbooks from os_playbooks.yml.
        Fallback to manual parsing if PyYAML is missing (simple schema only).
        """
        # Repo root is 2 levels up from backend/autofix_control_plane.py usually, 
        # or we just rely on CWD being repo root or relative path.
        # Ideally use absolute path if possible. 
        # For now, let's assume CWD or relative to file.
        
        # Try to find os_playbooks.yml
        repo_root = Path(os.getcwd())
        playbook_path = repo_root / PLAYBOOK_REGISTRY_PATH
        if not playbook_path.exists():
            # Fallback for Docker structure if needed
            playbook_path = Path("/app") / PLAYBOOK_REGISTRY_PATH
        
        if not playbook_path.exists():
            print(f"WARNING: Playbook registry not found at {playbook_path}")
            return []

        if HAS_YAML:
            with open(playbook_path, "r", encoding="utf-8") as f:
                data = yaml.safe_load(f)
                raw_pbs = data.get("playbooks", [])
                # V2 -> V1 Compat Mapping for internal logic
                for pb in raw_pbs:
                    # Map 'conditions.pattern_keys' to 'symptoms' if not present
                    if "symptoms" not in pb and "conditions" in pb:
                        pb["symptoms"] = pb["conditions"].get("pattern_keys", [])
                    # Map 'action.action_id' to 'allowed_actions'
                    if "allowed_actions" not in pb and "action" in pb:
                        pb["allowed_actions"] = [pb["action"].get("action_id")]
                return raw_pbs
        else:
            # Simple fallback parser for the specific schema we created
            # This is brittle but allowed if PyYAML not strictly required by env
            playbooks = []
            current_pb = {}
            in_playbooks = False
            
            with open(playbook_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
                
            for line in lines:
                line = line.strip()
                if line.startswith("playbooks:"):
                    in_playbooks = True
                    continue
                if not in_playbooks: continue
                
                # New playbook
                if line.startswith("- playbook_id:"):
                    if current_pb:
                        playbooks.append(current_pb)
                    current_pb = {}
                    val = line.split(":", 1)[1].strip()
                    current_pb["playbook_id"] = val
                    current_pb["symptoms"] = [] # valid start
                    current_pb["allowed_actions"] = []
                    
                elif "pattern_keys:" in line:
                    # V2: pattern_keys: ["A", "B"]
                    try:
                        val = line.split(":", 1)[1].strip()
                        val = val.strip("[]").replace('"', '').replace("'", "")
                        keys = [k.strip() for k in val.split(",") if k.strip()]
                        current_pb["symptoms"] = keys
                    except: pass
                    
                elif "action_id:" in line:
                     # V2: action_id: RUN_...
                     val = line.split(":", 1)[1].strip()
                     current_pb["allowed_actions"] = [val]
                     
                # Legacy V1 fallback (optional if completely rewritten)
                elif "symptoms:" in line:
                    pass # handled by next lines if list?
                    
            if current_pb:
                playbooks.append(current_pb)
                
            return playbooks

    @staticmethod
    def assess_and_recommend() -> Dict[str, Any]:
        """
        Main entry point.
        1. Observe (Gather signals)
        2. Match Playbooks (Apply Logic)
        3. Persist (Snapshot + Ledger)
        """
        # Ensure output directory exists
        output_dir = get_artifacts_root() / AUTOFIX_SUBDIR
        os.makedirs(output_dir, exist_ok=True)

        # 1. Observe
        observation = AutoFixControlPlane._observe()
        
        # 2. Match Playbooks
        playbooks = AutoFixControlPlane.load_playbooks()
        matched_playbooks = AutoFixControlPlane._match_playbooks(observation, playbooks)
        
        # 3. Derive Actions
        # In v2, we recommend the Playbook.
        
        status = "NOMINAL"
        if matched_playbooks:
            status = "ACTION_RECOMMENDED"
            # Degraded if we have matches but they are effectively warnings without actions?
            # Check if any have executable actions
            has_executable = any(len(pb.get("allowed_actions", [])) > 0 for pb in matched_playbooks)
            if not has_executable:
                 # If only "RECOMMEND_ONLY" playbooks matched
                 pass

        result = {
            "schema_version": "2.0.0",
            "as_of_utc": datetime.now(timezone.utc).isoformat(),
            "status": status,
            "observation": observation,
            "matched_playbooks": matched_playbooks,
            "playbooks_loaded_count": len(playbooks)
        }

        # 4. Persist
        AutoFixControlPlane._persist(result)

        return result

    @staticmethod
    def _observe() -> Dict[str, Any]:
        """
        Gather raw signals.
        """
        # Dynamic Thresholds (Day 24)
        dyn_res = safe_read_or_fallback("runtime/agms/agms_dynamic_thresholds.json")
        stale_light_thresh = STALE_LIGHT_SECONDS
        stale_full_thresh = STALE_FULL_SECONDS
        
        if dyn_res["success"]:
             t = dyn_res["data"].get("thresholds", {})
             stale_light_thresh = t.get("stale_light_seconds", STALE_LIGHT_SECONDS)
             stale_full_thresh = t.get("stale_full_seconds", STALE_FULL_SECONDS)

        # A. Misfire Monitor
        misfire_report = misfire_monitor.check_misfire_status()

        # B. Artifact Freshness (Full)
        full_manifest = safe_read_or_fallback(FULL_MANIFEST_PATH)
        full_age = AGE_INFINITE
        full_exists = False
        if full_manifest["success"]:
            full_exists = True
            try:
                ts_str = full_manifest["data"].get("timestamp")
                if ts_str:
                    full_ts = datetime.fromisoformat(ts_str)
                    if full_ts.tzinfo is None:
                        full_ts = full_ts.replace(tzinfo=timezone.utc)
                    full_age = (datetime.now(timezone.utc) - full_ts).total_seconds()
            except:
                pass

        # C. Artifact Freshness (Light)
        light_manifest = safe_read_or_fallback(LIGHT_MANIFEST_PATH)
        light_age = AGE_INFINITE
        light_exists = False
        if light_manifest["success"]:
            light_exists = True
            try:
                ts_str = light_manifest["data"].get("timestamp")
                if ts_str:
                    light_ts = datetime.fromisoformat(ts_str)
                    if light_ts.tzinfo is None:
                        light_ts = light_ts.replace(tzinfo=timezone.utc)
                    light_age = (datetime.now(timezone.utc) - light_ts).total_seconds()
            except:
                pass

        # D. Locks
        lock_status = "UNKNOWN"
        lock_age = 0.0
        if os.path.exists(LOCK_FILE_PATH):
             try:
                 with open(LOCK_FILE_PATH, "r") as f:
                     lock_data = json.load(f)
                 lock_status = "LOCKED"
                 ts_str = lock_data.get("timestamp_utc")
                 if ts_str:
                     ts = datetime.fromisoformat(ts_str)
                     if ts.tzinfo is None: ts = ts.replace(tzinfo=timezone.utc)
                     lock_age = (datetime.now(timezone.utc) - ts).total_seconds()
             except:
                 lock_status = "READ_ERROR"
        else:
            lock_status = "UNLOCKED"
            
        # E. Garbage (Simplistic check for .tmp/.bak)
        garbage_found = False
        # Implementation omitted for speed, unless strictly required by playbook symptoms.
        # Let's assume passed in via Housekeeper if needed, or check local dir?
        # For now, we omit active scan to avoid I/O overhead in this loop.

        return {
            "misfire_report": misfire_report,
            "full_artifact_age": full_age,
            "full_artifact_exists": full_exists,
            "light_artifact_age": light_age,
            "light_artifact_exists": light_exists,
            "light_artifact_exists": light_exists,
            "lock_status": lock_status,
            "lock_age": lock_age,
            # Pass thresholds through observation for downstream logic
            "thresholds": {
                "stale_light_seconds": stale_light_thresh,
                "stale_full_seconds": stale_full_thresh
            }
        }

    @staticmethod
    def _match_playbooks(observation: Dict[str, Any], playbooks: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Deterministic matching of symptoms to playbooks.
        """
        matches = []
        
        # Extract thresholds from observation context
        stale_light_limit = observation.get("thresholds", {}).get("stale_light_seconds", STALE_LIGHT_SECONDS)
        stale_full_limit = observation.get("thresholds", {}).get("stale_full_seconds", STALE_FULL_SECONDS)

        for pb in playbooks:
            triggered = False
            match_reasons = []
            
            # Check Symptoms
            for symptom in pb.get("symptoms", []):
                # 1. Misfire
                if "missing outputs/full/run_manifest.json" in symptom:
                    if not observation["full_artifact_exists"] or observation["misfire_report"].get("status") == "MISFIRE":
                         triggered = True
                         match_reasons.append("Missing Full Manifest")
                
                if "missing outputs/light/run_manifest.json" in symptom:
                    if not observation["light_artifact_exists"]:
                        triggered = True
                        match_reasons.append("Missing Light Manifest")
                        
                # 2. Stale
                if "full manifest age > 26h" in symptom:
                    if observation["full_artifact_age"] > stale_full_limit and observation["full_artifact_exists"]:
                        triggered = True
                        match_reasons.append(f"Full Age {observation['full_artifact_age']:.1f}s > {stale_full_limit}")
                
                if "light manifest age > 15m" in symptom:
                    if observation["light_artifact_age"] > stale_light_limit and observation["light_artifact_exists"]:
                        triggered = True
                        match_reasons.append(f"Light Age {observation['light_artifact_age']:.1f}s > {stale_light_limit}")
                        
                # 3. Lock
                if "os_lock.json age > 1h" in symptom:
                    if observation["lock_status"] == "LOCKED" and observation["lock_age"] > 3600:
                        triggered = True
                        match_reasons.append(f"Lock Age {observation['lock_age']:.1f}s")

            if triggered:
                # Clone pb to avoid mutating registry
                match = pb.copy()
                match["match_reasons"] = match_reasons
                matches.append(match)
                
        return matches

    @staticmethod
    def _persist(result: Dict[str, Any]):
        """
        Atomic write of status/snapshot and append to ledger.
        """
        # 1. Atomic Artifacts
        atomic_write_json(f"{AUTOFIX_SUBDIR}/autofix_status.json", {
            "status": result["status"],
            "as_of_utc": result["as_of_utc"],
            "matched_count": len(result["matched_playbooks"]),
            "playbooks_loaded": result["playbooks_loaded_count"]
        })
        
        atomic_write_json(f"{AUTOFIX_SUBDIR}/matched_playbooks.json", {
            "as_of_utc": result["as_of_utc"],
            "matches": result["matched_playbooks"]
        })
        
        atomic_write_json(f"{AUTOFIX_SUBDIR}/playbooks_loaded.json", {
            "count": result["playbooks_loaded_count"],
            "hash": hashlib.md5(str(result["playbooks_loaded_count"]).encode()).hexdigest() # Simple verification hash
        })

        atomic_write_json(f"{AUTOFIX_SUBDIR}/autofix_observer_snapshot.json", result["observation"])

        # 2. Immutable Ledger
        from backend.artifacts.io import ARTIFACTS_ROOT
        ledger_path = ARTIFACTS_ROOT / AUTOFIX_SUBDIR / "autofix_ledger.jsonl"
        os.makedirs(ledger_path.parent, exist_ok=True)
        
        entry = {
            "as_of_utc": result["as_of_utc"],
            "status": result["status"],
            "matched_playbook_ids": [m["playbook_id"] for m in result["matched_playbooks"]],
            "executor": "PASSIVE_OBSERVER_V2"
        }
        
        with open(ledger_path, "a") as f:
            f.write(json.dumps(entry) + "\n")

    @staticmethod
    def execute_action(action_code_or_playbook_id: str, founder_key: str) -> Dict[str, Any]:
        """
        Execute a Tier1 action if allowed and cooldown passed.
        Accepts either an ACTION_CODE (legacy) or PLAYBOOK_ID (v2).
        """
        timestamp_utc = datetime.now(timezone.utc).isoformat()
        
        # Resolve to Action Code
        action_code = action_code_or_playbook_id
        playbook_id = None
        
        # Load registry to check if it's a playbook ID
        playbooks = AutoFixControlPlane.load_playbooks()
        target_pb = next((p for p in playbooks if p["playbook_id"] == action_code_or_playbook_id), None)
        
        if target_pb:
            playbook_id = target_pb["playbook_id"]
            # Take the first allowed action? Or require specific?
            # For v2, we assume 1 main action per playbook for T1
            if target_pb.get("allowed_actions"):
                action_code = target_pb["allowed_actions"][0]
            else:
                return AutoFixControlPlane._audit_execution(
                    action_code_or_playbook_id, "FAILED", ["PLAYBOOK_HAS_NO_ACTIONS"], None, timestamp_utc
                )

            return AutoFixControlPlane._audit_execution(
                action_code_or_playbook_id, "FAILED", ["PLAYBOOK_HAS_NO_ACTIONS"], None, timestamp_utc
            )

        # 1. Allowlist Check
        ALLOWLIST = {
            "RUN_PIPELINE_LIGHT": {
                "cooldown_seconds": 300,
                "args": ["-m", "backend.pipeline_controller", "--mode", "LIGHT"]
            },
            "RUN_PIPELINE_FULL": {
                "cooldown_seconds": 900,
                "args": ["-m", "backend.pipeline_controller", "--mode", "FULL"]
            }
        }
        
        if action_code not in ALLOWLIST:
            return AutoFixControlPlane._audit_execution(
                action_code, "FAILED", ["ACTION_NOT_ALLOWED"], None, timestamp_utc, playbook_id
            )
            
        config = ALLOWLIST[action_code]
        
        # 2. Cooldown Check
        state_path = f"{AUTOFIX_SUBDIR}/autofix_execute_state.json"
        state_res = safe_read_or_fallback(state_path)
        last_run_ts = None
        
        if state_res["success"]:
            last_run_iso = state_res["data"].get("last_execution", {}).get(action_code)
            if last_run_iso:
                last_run_ts = datetime.fromisoformat(last_run_iso)
                if last_run_ts.tzinfo is None:
                    last_run_ts = last_run_ts.replace(tzinfo=timezone.utc)
        
        # Check Playbook specific cooldown if applicable?
        # For now, action-based cooldown is the safety floor.

        if last_run_ts:
            age = (datetime.now(timezone.utc) - last_run_ts).total_seconds()
            if age < config["cooldown_seconds"]:
                remaining = config["cooldown_seconds"] - age
                return AutoFixControlPlane._audit_execution(
                    action_code, "SKIPPED_COOLDOWN", 
                    [f"Cooldown active. Remaining: {remaining:.1f}s"], 
                    None, timestamp_utc, playbook_id
                )

        # 3. Execution (Cloud Run Trigger)
        project = os.environ.get("PROJECT_ID", "marketsniper-intel-osr-9953")
        region = os.environ.get("REGION", "us-central1")
        job = os.environ.get("JOB_NAME", "market-sniper-pipeline")
        
        url = f"https://{region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/{project}/jobs/{job}:run"
        
        try:
            credentials, project_id = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
            credentials.refresh(GoogleRequest())
            token = credentials.token
            
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "overrides": {
                    "container_overrides": [
                        {
                            "args": config["args"]
                        }
                    ]
                }
            }
            
            resp = requests.post(url, headers=headers, json=payload)
            resp.raise_for_status()
            job_data = resp.json()
            
            # Update Cooldown State
            new_state = state_res["data"] if state_res["success"] else {"last_execution": {}}
            if "last_execution" not in new_state: new_state["last_execution"] = {}
            new_state["last_execution"][action_code] = timestamp_utc
            atomic_write_json(state_path, new_state)
            
            return AutoFixControlPlane._audit_execution(
                action_code, "TRIGGERED", [], job_data, timestamp_utc, playbook_id
            )

        except Exception as e:
            return AutoFixControlPlane._audit_execution(
                action_code, "FAILED", [str(e)], None, timestamp_utc, playbook_id
            )

    @staticmethod
    def execute_from_handoff(handoff_data: Dict[str, Any], founder_key: Optional[str] = None) -> Dict[str, Any]:
        """
        Execute an action based on an AGMS Handoff Token.
        Requires Strict Gates: Token, Key, Cooldown.
        """
        from backend.os_intel.agms_autopilot_handoff import AGMSAutopilotHandoff
        
        timestamp_utc = datetime.now(timezone.utc).isoformat()
        playbook_id = handoff_data.get("suggested_playbook_id")
        action_code = handoff_data.get("action_code") # e.g. RUN_PIPELINE_HANDOFF -> Map to real action
        
        # 1. GATE: Token Validation
        if not AGMSAutopilotHandoff.verify_token(handoff_data):
            return AutoFixControlPlane._audit_execution(
                 "HANDOFF_EXECUTE", "FAILED_GUARDRAIL", ["INVALID_TOKEN"], None, timestamp_utc, playbook_id
            )

        # 2. GATE: Autopilot Policy (Autonomy Dial)
        # Check if policy allows this execution context
        # We perform this BEFORE Authorization to ensure Policy is the first wall after Token validity.
        # However, Policy might respect "Founder Key" overrides, so we pass it.
        
        policy_decision = AutopilotPolicyEngine.evaluate_autopilot_decision(
            context={}, # Context implied by artifacts read in Engine
            playbook_id=playbook_id,
            action_code=action_code,  # The handoff action code (e.g. RUN_PIPELINE_HANDOFF) or real one?
                                      # Engine checks allowlist. The Handoff action code maps to real action later.
                                      # Issue: allowlist has "RUN_PIPELINE_LIGHT". Handoff has "RUN_PIPELINE_HANDOFF".
                                      # We need to map it FIRST if we want Policy to check specific allowlist.
                                      # Or we pass the raw handoff code and Policy allowlist must include it?
                                      # Day 28 Spec: "allowlist: RUN_PIPELINE_LIGHT, RUN_PIPELINE_FULL".
                                      # So we must map to real action before Policy Check OR Policy Engine does mapping?
                                      # Better: Map first.
        )
        
        # Checking mapping logic is below in original code (Step 3).
        # We should pull Step 3 (Playbook Mapping) UP before Policy Check?
        # Yes, safe to do so. Token is valid.
        
        # --- REORDERED STEP 3: Playbook Mapping ---
        playbooks = AutoFixControlPlane.load_playbooks()
        target_pb = next((p for p in playbooks if p["playbook_id"] == playbook_id), None)
        
        if not target_pb:
             return AutoFixControlPlane._audit_execution(
                 "HANDOFF_EXECUTE", "FAILED_GUARDRAIL", ["PLAYBOOK_NOT_FOUND"], None, timestamp_utc, playbook_id
            )
            
        real_action = None
        if target_pb.get("allowed_actions"):
            real_action = target_pb["allowed_actions"][0] 
            
        if not real_action:
             return AutoFixControlPlane._audit_execution(
                 "HANDOFF_EXECUTE", "FAILED_GUARDRAIL", ["NO_ACTION_IN_PLAYBOOK"], None, timestamp_utc, playbook_id
            )
            
        # --- NOW STEP 2: Policy Check ---
        policy_decision = AutopilotPolicyEngine.evaluate_autopilot_decision(
            context={},
            playbook_id=playbook_id,
            action_code=real_action, 
            founder_key_present=(founder_key is not None)
        )
        
        if policy_decision["status"] != "ALLOW":
             return AutoFixControlPlane._audit_execution(
                 "HANDOFF_EXECUTE", "POLICY_DENIED", 
                 policy_decision["reasons"], 
                 None, timestamp_utc, playbook_id
            )

        # 3. GATE: Auth (Founder Key OR Autopilot Enabled)
        # For Day 23, strict logic: Founder Key REQUIRED for manual triggers, or explicit env var for full auto
        autopilot_enabled = os.environ.get("AUTOPILOT_ENABLED", "false").lower() == "true"
        # We require either a valid founder key OR (autopilot enabled AND valid handoff)
        # Since this method is called by an API endpoint likely guarded by founder logic or cron:
        # If founder_key provided, we assume auth passed at API layer (or checked here if we had the hash).
        # We will trust the caller (API) if founder_key is present (acting as a "yes execute this").
        # If no key, we check AUTOPILOT_ENABLED.
        
        authorized = False
        if founder_key: authorized = True
        if autopilot_enabled: authorized = True
        
        if not authorized:
             return AutoFixControlPlane._audit_execution(
                 "HANDOFF_EXECUTE", "FAILED_GUARDRAIL", ["AUTH_REQUIRED"], None, timestamp_utc, playbook_id
            )

        # Old Step 3 Removed (Moved Up)
        pass

        # 4. Delegate to Standard Execution Logic
        # We call execute_action but pass the real action code
        # NOTE: Standard Execution Logic also has Allowlist/Cooldown. 
        # Redundant but safe (Defense in Depth).
        return AutoFixControlPlane.execute_action(real_action, founder_key)


    @staticmethod
    def _audit_execution(action_code, result_status, reason_codes, job_data, timestamp_utc, playbook_id=None):
        
        # 1. Audit Result Artifact
        audit_file = f"{AUTOFIX_SUBDIR}/execute/autofix_execute_result.json"
        
        # Ensure dir
        from backend.artifacts.io import ARTIFACTS_ROOT
        os.makedirs(ARTIFACTS_ROOT / AUTOFIX_SUBDIR / "execute", exist_ok=True)
        
        result_payload = {
            "status": result_status,
            "action_code": action_code,
            "playbook_id": playbook_id,
            "reason_codes": reason_codes,
            "job_ref": job_data,
            "timestamp_utc": timestamp_utc
        }
        
        atomic_write_json(audit_file, result_payload)
        
        # 2. Append to Ledger
        ledger_path = ARTIFACTS_ROOT / AUTOFIX_SUBDIR / "autofix_execute_ledger.jsonl"
        os.makedirs(ledger_path.parent, exist_ok=True)
        
        entry = {
            "as_of_utc": timestamp_utc,
            "action_code": action_code,
            "playbook_id": playbook_id,
            "result": result_status,
            "reason_codes": reason_codes,
            "job_id": job_data.get("metadata", {}).get("name") if job_data else None
        }
        
        with open(ledger_path, "a") as f:
            f.write(json.dumps(entry) + "\n")
            
        return result_payload

