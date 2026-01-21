import json
import shutil
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional, Literal, Dict
from pydantic import BaseModel, Field

# --- CONFIGURATION ---
ROOT_DIR = Path("c:/MSR/MarketSniperRepo").resolve()
OUTPUTS_DIR = ROOT_DIR / "outputs"
OS_DIR = OUTPUTS_DIR / "os"
PROOFS_DIR = OUTPUTS_DIR / "proofs/day_42"
BACKUP_DIR = OUTPUTS_DIR / "backups/autofix"

PLAN_PATH = OS_DIR / "os_autofix_plan.json"
PROOF_PATH = PROOFS_DIR / "day_42_04_autofix_tier1_proof.json"
LATEST_DIFF_PATH = OS_DIR / "os_before_after_diff.json"
FINDINGS_PATH = OS_DIR / "os_findings.json"

ALLOWLIST_TIER1_ACTIONS = ["REGENERATE_MISSING_ARTIFACT", "REPAIR_SCHEMA_DRIFT", "CLEAR_STALE_FLAGS"]

class AutoFixAction(BaseModel):
    action_code: str
    target: Optional[str] = None
    description: str
    reversible: bool
    risk_tier: str
    parameters: Dict = {}

class AutoFixPlan(BaseModel):
    plan_id: str
    timestamp_utc: datetime
    trigger_context: str
    actions: List[AutoFixAction]

class BackupRecord(BaseModel):
    original_path: str
    backup_path: str
    timestamp_utc: datetime
    sha256: str

class ActionResult(BaseModel):
    action_code: str
    target: Optional[str]
    status: Literal["SUCCESS", "FAILED", "SKIPPED"]
    reason: Optional[str] = None
    backup: Optional[BackupRecord] = None

class AutoFixRunResult(BaseModel):
    run_id: str
    timestamp_utc: datetime
    plan_id: Optional[str]
    trigger_context: str
    status: Literal["NOOP", "SUCCESS", "PARTIAL", "FAILED"]
    actions_executed: int
    actions_skipped: int
    actions_failed: int
    results: List[ActionResult]


DECISION_PATH_PATH = OS_DIR / "os_autofix_decision_path.json"

class AutoFixActionEvaluation(BaseModel):
    allowlisted: bool
    tier_allowed: bool
    reversible_ok: bool
    path_allowed: bool
    founder_override_used: bool

class DecisionAction(BaseModel):
    action_code: str
    target: Optional[str] = None
    reversible: bool
    risk_tier: str
    evaluation: AutoFixActionEvaluation
    outcome: Literal["EXECUTED", "SKIPPED", "BLOCKED", "REJECTED"]
    reason: str

class AutoFixDecisionPath(BaseModel):
    run_id: str
    plan_id: Optional[str]
    timestamp_utc: datetime
    trigger_context: str
    overall_status: Literal["NO_OP", "SUCCESS", "PARTIAL", "FAILED", "BLOCKED"]
    rules_applied: List[str]
    actions: List[DecisionAction]

class AutoFixTier1:
    @staticmethod
    def _create_backup(target_path: Path) -> BackupRecord:
        """Creates a reversible backup of the target file."""
        if not target_path.exists():
            return None

        timestamp_str = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        backup_filename = f"{target_path.name}.{timestamp_str}.bak"
        backup_path = BACKUP_DIR / backup_filename
        
        BACKUP_DIR.mkdir(parents=True, exist_ok=True)
        shutil.copy2(target_path, backup_path)
        
        # Calculate SHA256
        sha256_hash = hashlib.sha256()
        with open(target_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
                
        return BackupRecord(
            original_path=str(target_path),
            backup_path=str(backup_path),
            timestamp_utc=datetime.now(timezone.utc),
            sha256=sha256_hash.hexdigest()
        )

    @staticmethod
    def _execute_action_with_decision(action: AutoFixAction, founder_context: bool = False) -> (ActionResult, DecisionAction):
        """Executes a single action and returns both result and decision detail."""
        
        # Defaults
        evaluation = AutoFixActionEvaluation(
            allowlisted=False,
            tier_allowed=False,
            reversible_ok=False,
            path_allowed=False,
            founder_override_used=founder_context
        )
        outcome = "SKIPPED"
        reason = "Unknown"
        
        # 1. Check Allowlist
        evaluation.allowlisted = action.action_code in ALLOWLIST_TIER1_ACTIONS
        if not evaluation.allowlisted:
            reason = f"Action '{action.action_code}' not in TIER_1 allowlist."
            return ActionResult(action_code=action.action_code, target=action.target, status="SKIPPED", reason=reason), \
                   DecisionAction(action_code=action.action_code, target=action.target, reversible=action.reversible, risk_tier=action.risk_tier, evaluation=evaluation, outcome="REJECTED", reason=reason)

        # 2. Check Reversible & Tier
        evaluation.reversible_ok = action.reversible
        if not evaluation.reversible_ok:
             reason = "Action must be reversible."
             return ActionResult(action_code=action.action_code, target=action.target, status="SKIPPED", reason=reason), \
                   DecisionAction(action_code=action.action_code, target=action.target, reversible=action.reversible, risk_tier=action.risk_tier, evaluation=evaluation, outcome="REJECTED", reason=reason)
        
        evaluation.tier_allowed = action.risk_tier in ["TIER_0", "TIER_1"]
        if not evaluation.tier_allowed:
             reason = f"Risk tier '{action.risk_tier}' too high."
             return ActionResult(action_code=action.action_code, target=action.target, status="SKIPPED", reason=reason), \
                   DecisionAction(action_code=action.action_code, target=action.target, reversible=action.reversible, risk_tier=action.risk_tier, evaluation=evaluation, outcome="REJECTED", reason=reason)

        try:
            target_path = Path(action.target) if action.target else None
            backup = None
            
            # Path Security Check
            full_path = None
            if target_path:
                full_path = (ROOT_DIR / target_path).resolve()
                is_safe = str(full_path).startswith(str(OUTPUTS_DIR))
                evaluation.path_allowed = is_safe or founder_context
                
                if not evaluation.path_allowed:
                    reason = "Target outside safe OUTPUTS_DIR (Founder required)"
                    return ActionResult(action_code=action.action_code, target=action.target, status="FAILED", reason=reason), \
                           DecisionAction(action_code=action.action_code, target=action.target, reversible=action.reversible, risk_tier=action.risk_tier, evaluation=evaluation, outcome="BLOCKED", reason=reason)
            else:
                 # Some actions might not have target? Assuming target required for now based on implementation
                 evaluation.path_allowed = True # N/A

            # ... Execution Logic ...
            action_res = None
            
            if action.action_code == "REGENERATE_MISSING_ARTIFACT":
                if not full_path:
                     raise Exception("Missing target")
                
                if full_path.exists():
                     reason = "Target already exists"
                     outcome = "SKIPPED"
                     action_res = ActionResult(action_code=action.action_code, target=action.target, status="SKIPPED", reason=reason)
                else:
                    full_path.parent.mkdir(parents=True, exist_ok=True)
                    content = action.parameters.get("default_content", {})
                    with open(full_path, "w") as f:
                        if isinstance(content, (dict, list)):
                            json.dump(content, f, indent=2)
                        else:
                            f.write(str(content))
                    outcome = "EXECUTED"
                    reason = "Artifact regenerated"
                    action_res = ActionResult(action_code=action.action_code, target=action.target, status="SUCCESS")

            elif action.action_code == "REPAIR_SCHEMA_DRIFT":
                if not full_path or not full_path.exists():
                     raise Exception("Target not found")
                
                backup = AutoFixTier1._create_backup(full_path)
                with open(full_path, "r") as f:
                    data = json.load(f)
                
                required_keys = action.parameters.get("required_keys", {})
                modified = False
                for k, v in required_keys.items():
                    if k not in data:
                        data[k] = v
                        modified = True
                
                if modified:
                    with open(full_path, "w") as f:
                        json.dump(data, f, indent=2)
                    outcome = "EXECUTED"
                    reason = "Schema repaired (keys added)"
                    action_res = ActionResult(action_code=action.action_code, target=action.target, status="SUCCESS", backup=backup)
                else:
                     outcome = "SKIPPED"
                     reason = "No drift detected"
                     action_res = ActionResult(action_code=action.action_code, target=action.target, status="SKIPPED", reason=reason, backup=backup)

            elif action.action_code == "CLEAR_STALE_FLAGS":
                 if not full_path or not full_path.exists():
                     raise Exception("Target not found")
                 
                 backup = AutoFixTier1._create_backup(full_path)
                 with open(full_path, "r") as f:
                    data = json.load(f)
                 
                 flags_to_clear = action.parameters.get("flags", [])
                 modified = False
                 for flag in flags_to_clear:
                     if flag in data and data[flag] is not False:
                         data[flag] = False
                         modified = True
                         
                 if modified:
                    with open(full_path, "w") as f:
                        json.dump(data, f, indent=2)
                    outcome = "EXECUTED"
                    reason = "Flags cleared"
                    action_res = ActionResult(action_code=action.action_code, target=action.target, status="SUCCESS", backup=backup)
                 else:
                     outcome = "SKIPPED"
                     reason = "Flags already clear"
                     action_res = ActionResult(action_code=action.action_code, target=action.target, status="SKIPPED", reason=reason, backup=backup)
            
            else:
                 # Should be caught by allowlist check, but just in case
                 outcome = "REJECTED"
                 reason = "Unknown Action"
                 action_res = ActionResult(action_code=action.action_code, target=action.target, status="FAILED", reason=reason)

            decision = DecisionAction(
                action_code=action.action_code,
                target=action.target,
                reversible=action.reversible,
                risk_tier=action.risk_tier,
                evaluation=evaluation,
                outcome=outcome,
                reason=reason
            )
            return action_res, decision

        except Exception as e:
            reason = str(e)
            return ActionResult(action_code=action.action_code, target=action.target, status="FAILED", reason=reason), \
                   DecisionAction(
                        action_code=action.action_code,
                        target=action.target,
                        reversible=action.reversible,
                        risk_tier=action.risk_tier,
                        evaluation=evaluation,
                        outcome="BLOCKED" if "outside safe" in str(e) else "REJECTED", # Generalized failure mapping
                        reason=reason
                   )

    @staticmethod
    def run_from_plan(founder_context: bool = False) -> AutoFixRunResult:
        run_id = f"AFX_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}"
        timestamp = datetime.now(timezone.utc)
        
        # 1. Plan Loading
        if not PLAN_PATH.exists():
            # Decision Path for Missing Plan involves NOT creating one? 
            # Or creating a NO_OP decision path?
            # Contracts say "This artifact is GENERATED by AutoFix Tier 1 during execution".
            # If we don't execute a plan, do we generate a decision path?
            # "Missing artifacts MUST degrade cleanly to UNAVAILABLE" regarding the UI reading it.
            # If we run and find no plan, we essentially did nothing. 
            # Let's clean up or overwrite the decision path to reflect "NO PLAN" or leave it?
            # "Mirror recorded facts". Fact is: No plan found.
            # Let's write a decision path for this too, for visibility.
            result = AutoFixRunResult(
                run_id=run_id,
                timestamp_utc=timestamp,
                plan_id=None,
                trigger_context="UNKNOWN",
                status="NOOP",
                actions_executed=0,
                actions_skipped=0,
                actions_failed=0,
                results=[]
            )
            
            # Decision Path for Missing Plan
            dpath = AutoFixDecisionPath(
                run_id=run_id,
                plan_id=None,
                timestamp_utc=timestamp,
                trigger_context="UNKNOWN",
                overall_status="NO_OP",
                rules_applied=["PLAN_MUST_EXIST"],
                actions=[]
            )
            AutoFixTier1._write_decision_path(dpath)
            AutoFixTier1._write_proof(result)
            return result

        try:
            with open(PLAN_PATH, "r") as f:
                raw_plan = json.load(f)
            plan = AutoFixPlan(**raw_plan)
        except Exception as e:
             # Invalid Plan
             result = AutoFixRunResult(
                run_id=run_id,
                timestamp_utc=timestamp,
                plan_id="INVALID",
                trigger_context="UNKNOWN",
                status="NOOP",
                actions_executed=0,
                actions_skipped=0,
                actions_failed=0,
                results=[ActionResult(action_code="PLAN_LOAD", target=None, status="FAILED", reason=str(e))]
            )
             dpath = AutoFixDecisionPath(
                run_id=run_id,
                plan_id="INVALID",
                timestamp_utc=timestamp,
                trigger_context="UNKNOWN",
                overall_status="FAILED",
                rules_applied=["PLAN_SCHEMA_VALIDATION"],
                actions=[]
            )
             AutoFixTier1._write_decision_path(dpath)
             AutoFixTier1._write_proof(result)
             return result

        # 2. Execution
        results = []
        decisions: List[DecisionAction] = []
        executed_count = 0
        skipped_count = 0
        failed_count = 0
        
        processed_something = False

        if not plan.actions:
             pass
        else:
             for action in plan.actions:
                res, decision = AutoFixTier1._execute_action_with_decision(action, founder_context)
                results.append(res)
                decisions.append(decision)
                
                if res.status == "SUCCESS":
                    executed_count += 1
                    processed_something = True
                elif res.status == "SKIPPED":
                    skipped_count += 1
                elif res.status == "FAILED":
                    failed_count += 1

        # 3. Artifact Updates
        if processed_something:
            AutoFixTier1._update_artifacts(results, timestamp)

        # 4. Result Construction
        final_status = "SUCCESS"
        if failed_count > 0:
            final_status = "FAILED" if executed_count == 0 else "PARTIAL"
        elif executed_count == 0:
            final_status = "NOOP"
            if skipped_count > 0:
                 if skipped_count == len(plan.actions):
                     final_status = "PARTIAL" 
        
        # Decision Path Construction
        # Map run status to decision path status
        dpath_status = "NO_OP"
        if final_status == "SUCCESS": dpath_status = "SUCCESS"
        elif final_status == "PARTIAL": dpath_status = "PARTIAL"
        elif final_status == "FAILED": dpath_status = "FAILED"
        elif final_status == "NOOP": dpath_status = "NO_OP"
        
        # Check for blocked specifically? The prompt maps overall_status: Literal["NO_OP","SUCCESS","PARTIAL","FAILED","BLOCKED"]
        # If all actions were blocked, maybe BLOCKED?
        # Let's keep it simple mapping from run result for now. Partition BLOCKED if needed.
        # If any action was BLOCKED in decision, maybe PARTIAL or BLOCKED? 
        # For now, standard mapping.
        
        dpath = AutoFixDecisionPath(
            run_id=run_id,
            plan_id=plan.plan_id,
            timestamp_utc=timestamp,
            trigger_context=plan.trigger_context,
            overall_status=dpath_status,
            rules_applied=["ALLOWLIST_CHECK", "REVERSIBLE_CHECK", "TIER_CHECK", "PATH_CHECK"],
            actions=decisions
        )
        AutoFixTier1._write_decision_path(dpath)

        run_result = AutoFixRunResult(
            run_id=run_id,
            timestamp_utc=timestamp,
            plan_id=plan.plan_id,
            trigger_context=plan.trigger_context,
            status=final_status,
            actions_executed=executed_count,
            actions_skipped=skipped_count,
            actions_failed=failed_count,
            results=results
        )

        AutoFixTier1._write_proof(run_result, processed_something)
        return run_result

    @staticmethod
    def _write_decision_path(dpath: AutoFixDecisionPath):
        OS_DIR.mkdir(parents=True, exist_ok=True)
        with open(DECISION_PATH_PATH, "w") as f:
            f.write(dpath.json(indent=2))

    @staticmethod
    def _update_artifacts(results: List[ActionResult], timestamp: datetime):
        # Update os_before_after_diff.json
        diff_snapshot = {
            "timestamp_utc": timestamp.isoformat(),
            "type": "AUTOFIX_TIER1_RUN",
            "changes": [
                {
                    "target": r.target,
                    "action": r.action_code,
                    "backup": r.backup.backup_path if r.backup else None
                }
                for r in results if r.status == "SUCCESS"
            ]
        }
        
        OS_DIR.mkdir(parents=True, exist_ok=True)
        with open(LATEST_DIFF_PATH, "w") as f:
            json.dump(diff_snapshot, f, indent=2)

        # Update os_findings.json
        new_finding = {
             "id": f"AFX_RUN_{timestamp.strftime('%H%M%S')}",
             "timestamp": timestamp.isoformat(),
             "title": "AutoFix Tier 1 Run",
             "description": f"Executed {len([r for r in results if r.status=='SUCCESS'])} actions.",
             "severity": "INFO",
             "source": "AUTOFIX_TIER1"
        }
        
        current_findings = []
        if FINDINGS_PATH.exists():
            try:
                with open(FINDINGS_PATH, "r") as f:
                    current_findings = json.load(f)
                    if not isinstance(current_findings, list):
                        current_findings = []
            except:
                current_findings = []
        
        current_findings.append(new_finding)
        with open(FINDINGS_PATH, "w") as f:
            json.dump(current_findings, f, indent=2)

    @staticmethod
    def _write_proof(result: AutoFixRunResult, findings_updated: bool = False):
        proof_data = result.dict()
        proof_data["timestamp_utc"] = result.timestamp_utc.isoformat()
        proof_data["findings_updated"] = findings_updated
        proof_data["before_after_updated"] = findings_updated # Logic link
        
        proof_data["results"] = [r.dict() for r in result.results]
        for r in proof_data["results"]:
             if r["backup"]:
                 r["backup"]["timestamp_utc"] = r["backup"]["timestamp_utc"].isoformat()

        # Add backups_created list helper for easy parsing
        proof_data["backups_created"] = [r["backup"]["backup_path"] for r in proof_data["results"] if r.get("backup")]
        proof_data["actions_requested"] = len(result.results)
        
        PROOFS_DIR.mkdir(parents=True, exist_ok=True)
        with open(PROOF_PATH, "w") as f:
            json.dump(proof_data, f, indent=2)
