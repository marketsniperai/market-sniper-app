import os
import json
import heapq
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Any
from backend.artifacts.io import get_artifacts_root, safe_read_or_fallback
# from backend.misfire_monitor import MisfireMonitor (Not a class, using artifact read instead)
from backend.os_ops.autofix_control_plane import AutoFixControlPlane
from backend.os_ops.housekeeper import Housekeeper
from backend.os_ops.iron_os import IronOS

class WarRoom:
    """
    Day 19: War Room Command Center (Titanium Upgrade).
    Aggregates autonomous systems, unified timelines, and truth comparisons (Playbooks/Contracts).
    Read-Only. Founder-Gated.
    """
    
    @staticmethod
    def get_dashboard() -> Dict[str, Any]:
        """
        Returns the full War Room Dashboard payload.
        """
        root = get_artifacts_root()
        now = datetime.now(timezone.utc)
        
        # 1. Module Status Aggregation
        # Live calls to obtain current "Status" struct from each module
        
        # AutoFix (Observation Only) - Now returns Playbook matches
        autofix_status_raw = AutoFixControlPlane.assess_and_recommend()
        
        # Housekeeper (Scan Only)
        housekeeper_scan_raw = Housekeeper.scan()
        
        # Misfire (Check Only)
        misfire_report = safe_read_or_fallback("misfire_report.json")
        
        # Autopilot Policy (Day 28)
        policy_snapshot = safe_read_or_fallback("runtime/autopilot/autopilot_policy_snapshot.json")
        if policy_snapshot["success"]:
            policy_data = policy_snapshot["data"]
            # Day 30: Add Visual Label
            if policy_data.get("mode") == "SAFE_AUTOPILOT":
                policy_data["ui_label"] = "SAFE_AUTOPILOT ACTIVE (GREEN ONLY)"
            elif policy_data.get("mode") == "SHADOW":
                policy_data["ui_label"] = "SHADOW OBSERVATION"
        else:
            policy_data = {"status": "UNKNOWN", "mode": "UNKNOWN"}

        # Playbook Coverage (Day 28.01)
        cov_rep = safe_read_or_fallback("runtime/playbooks/playbook_coverage_report.json")
        cov_data = cov_rep["data"] if cov_rep["success"] else {"status": "UNKNOWN"}
        
        # Shadow Repair Proposal (Day 28.02)
        sr_prop = safe_read_or_fallback("runtime/shadow_repair/patch_proposal.json")
        sr_data = {"status": "NONE"}
        if sr_prop["success"]:
            # Check freshness (e.g. < 24h)
            try: 
                 created = datetime.fromisoformat(sr_prop["data"]["created_utc"])
                 if (now - created).total_seconds() < 86400:
                     sr_data = {
                         "status": "READY",
                         "proposal_id": sr_prop["data"]["proposal_id"],
                         "risk_tags": sr_prop["data"]["risk_tags"],
                         "owner": sr_prop["data"]["mapped_contract_id"]
                     }
            except: pass
            
        # Day 31: Check for Runtime Patches (The Surgeon)
        sr_data["latest_runtime_patch"] = WarRoom._get_latest_runtime_patch()

        # Autopilot Shadow Lane (Day 29)
        shadow_summary = WarRoom._get_shadow_summary()

        modules = {
            "autofix": {
                "status": autofix_status_raw.get("status"),
                "matched_playbooks": autofix_status_raw.get("matched_playbooks", []),
                "playbooks_loaded": autofix_status_raw.get("playbooks_loaded_count", 0),
                # Legacy compat if UI needs it, though we prefer matched_playbooks now
                "legacy_observation": autofix_status_raw.get("observation")
            },
            "housekeeper": housekeeper_scan_raw,
            "misfire": misfire_report.get("data") if misfire_report["success"] else "UNKNOWN",
            "agms": {
                "foundation": WarRoom._get_agms_status(root),
                "intelligence": WarRoom._get_agms_intelligence(root)
            },
            "autopilot_policy": policy_data,
            "playbook_coverage": cov_data,
            "shadow_repair": sr_data,
            "playbook_coverage": cov_data,
            "shadow_repair": sr_data,
            "autopilot_shadow_summary": shadow_summary,
            "immune_system": WarRoom._get_immune_status(root),
            "black_box": WarRoom._get_black_box_status(),
            "dojo": WarRoom._get_dojo_status(root),
            "tuning_gate": WarRoom._get_tuning_status(root),
            "dojo": WarRoom._get_dojo_status(root),
            "tuning_gate": WarRoom._get_tuning_status(root),
            "iron_os_status": IronOS.get_status(),
            "timestamp_utc": now.isoformat()
        }
        
        # 2. Unified Forensic Timeline
        timeline = WarRoom._build_timeline(root)
        
        # 3. Truth Compare (Runtime vs Canon/Contracts)
        truth_compare = WarRoom._compare_truth(root, now)
        
        # 4. Evidence Surface
        evidence = WarRoom._gather_evidence(root, autofix_status_raw.get("matched_playbooks", []))
        
        return {
            "timestamp_utc": now.isoformat(),
            "modules": modules,
            "truth_compare": truth_compare,
            "evidence": evidence,
            "timeline": timeline
        }

    @staticmethod
    def _build_timeline(root) -> List[Dict[str, Any]]:
        """
        Merges ledgers into a single reverse-chronological timeline.
        """
        events = []
        
        # Define sources
        sources = [
            # (path, type_label, time_key)
            ("runtime/autofix/autofix_ledger.jsonl", "AUTOFIX_OBSERVE", "as_of_utc"), # adjusted key
            ("runtime/autofix/autofix_execute_ledger.jsonl", "AUTOFIX_EXECUTE", "as_of_utc"),
            ("runtime/housekeeper/housekeeper_ledger.jsonl", "HOUSEKEEPER_CLEAN", "timestamp_utc")
        ]
        
        for rel_path, label, time_key in sources:
            path = root / rel_path
            if path.exists():
                try:
                    with open(path, "r") as f:
                        for line in f:
                            if not line.strip(): continue
                            record = json.loads(line)
                            
                            # Normalize timestamp
                            ts_str = record.get(time_key)
                            # Fallback if key mistyped in ledgers
                            if not ts_str: ts_str = record.get("timestamp_utc")
                            if not ts_str: continue 
                            
                            # Extract Playbook ID if present
                            pb_id = record.get("matched_playbook_ids") or record.get("playbook_id")
                            
                            events.append({
                                "timestamp": ts_str,
                                "source": label,
                                "playbook_id": pb_id,
                                "details": record
                            })
                except Exception:
                    pass # Resilience: Skip broken ledgers
                    
        # Sort desc
        events.sort(key=lambda x: x["timestamp"], reverse=True)
        return events[:100] # Tail 100

    @staticmethod
    def _compare_truth(root, now_utc) -> List[Dict[str, Any]]:
        """
        Compares expected state vs runtime state using OS Contracts.
        """
        checks = []
        
        # Load Contracts
        # Assuming contract file is in repo root or mapped volume.
        # Since War Room runs in backend container, we can check relative or /app
        # We try to find it.
        contract_path = Path("os_module_contracts.json")
        if not contract_path.exists():
             contract_path = Path("/app/os_module_contracts.json")
        if not contract_path.exists():
             # Fallback to backend parent?
             contract_path = Path("../os_module_contracts.json")
             
        contracts = {}
        if contract_path.exists():
             try:
                 with open(contract_path, "r") as f:
                     contracts = json.load(f)
             except:
                 checks.append({"target": "os_module_contracts", "status": "ERROR", "actual": "READ_FAIL"})

        # Contract Checks
        modules = contracts.get("modules", {})
        
        # 1. Misfire Monitor Check
        mm = modules.get("misfire_monitor", {})
        for art in mm.get("artifacts", []):
             p = root / art
             if p.exists():
                 checks.append({"target": art, "status": "PRESENT", "actual": "EXISTS"})
             else:
                 checks.append({"target": art, "status": "MISSING", "actual": "NOT_FOUND"})
                 
        # 2. Autofix Check
        af = modules.get("autofix", {})
        for art in af.get("artifacts", []):
             p = root / art
             if p.exists():
                 checks.append({"target": art, "status": "PRESENT", "actual": "EXISTS"})
             else:
                 checks.append({"target": art, "status": "MISSING", "actual": "NOT_FOUND"})

        # 3. Lock Check (Standard)
        p_lock = root / "os_lock.json" 
        if p_lock.exists():
             checks.append({"target": "os_lock", "status": "ACTIVE", "actual": "LOCKED"})
        else:
             checks.append({"target": "os_lock", "status": "FREE", "actual": "NO_LOCK"})
             
        return checks
        
    @staticmethod
    def _gather_evidence(root, matched_playbooks) -> List[Dict[str, Any]]:
        """
        Collects evidence for matched playbooks.
        """
        evidence = []
        seen_paths = set()
        
        for pb in matched_playbooks:
            for path in pb.get("evidence_paths", []):
                if path in seen_paths: continue
                seen_paths.add(path)
                
                p = root / path
                exists = p.exists()
                mtime_str = None
                if exists:
                    mtime = datetime.fromtimestamp(p.stat().st_mtime, tz=timezone.utc)
                    mtime_str = mtime.isoformat()
                    
                evidence.append({
                    "path": path,
                    "exists": exists,
                    "updated_at": mtime_str
                })
        
        return evidence

    @staticmethod
    def _get_agms_status(root) -> Dict[str, Any]:
        """
        Retrieves AGMS Foundation status (Snapshot).
        """
        # We could call AGMSFoundation.run_agms_foundation() live,
        # OR read the last snapshot.
        # "War Room is Read-Only" implies we should ideally read artifact 
        # unless we want live truth.
        # Let's read the artifact to be safe and fast.
        path = root / "runtime/agms/agms_snapshot.json"
        if path.exists():
            try:
                with open(path, "r") as f:
                    return json.load(f)
            except:
                return {"status": "READ_ERROR"}
        return {"status": "NOT_FOUND"}

    @staticmethod
    def _get_agms_intelligence(root) -> Dict[str, Any]:
        """
        Retrieves Coherence and Patterns (Read-Only).
        """
        p_coh = root / "runtime/agms/agms_coherence_snapshot.json"
        p_pat = root / "runtime/agms/agms_patterns.json"
        p_shadow = root / "runtime/agms/agms_shadow_snapshot.json"
        p_handoff = root / "runtime/agms/agms_handoff.json"
        p_exec = root / "runtime/autofix/execute/autofix_execute_result.json"
        p_thresh = root / "runtime/agms/agms_dynamic_thresholds.json"
        p_band = root / "runtime/agms/agms_stability_band.json"
        
        intel = {
            "coherence": None, 
            "top_pattern": None, 
            "shadow_suggestions": [],
            "autopilot": {
                "latest_handoff": None,
                "latest_execution": None
            },
            "thresholds": None,
            "stability_band": None
        }
        
        if p_coh.exists():
            try:
                with open(p_coh, "r") as f:
                    intel["coherence"] = json.load(f)
            except: pass
            
        if p_pat.exists():
            try:
                with open(p_pat, "r") as f:
                    data = json.load(f)
                    if data.get("top_drift_types"):
                        intel["top_pattern"] = data["top_drift_types"][0]
            except: pass
            
        if p_shadow.exists():
             try:
                 with open(p_shadow, "r") as f:
                     snap = json.load(f)
                     intel["shadow_suggestions"] = snap.get("suggestions", [])
             except: pass

        if p_handoff.exists():
             try:
                 with open(p_handoff, "r") as f:
                     h = json.load(f)
                     intel["autopilot"]["latest_handoff"] = h.get("handoff")
             except: pass
             
        if p_exec.exists():
             try:
                 with open(p_exec, "r") as f:
                     e = json.load(f)
                     intel["autopilot"]["latest_execution"] = e
             except: pass
             
        if p_thresh.exists():
             try:
                 with open(p_thresh, "r") as f:
                     t = json.load(f)
                     intel["thresholds"] = t
             except: pass

        if p_band.exists():
             try:
                 with open(p_band, "r") as f:
                     b = json.load(f)
                     intel["stability_band"] = b
             except: pass
            
        return intel

    @staticmethod
    def _get_shadow_summary() -> Dict[str, Any]:
        """
        Day 29: Aggregates Shadow Ledger stats.
        """
        root = get_artifacts_root()
        ledger = root / "runtime/autopilot/autopilot_shadow_decisions.jsonl"
        
        summary = {
            "total_decisions": 0,
            "allow_count": 0,
            "deny_count": 0,
            "top_deny_reasons": [],
            "last_decision": "NONE"
        }
        
        if not ledger.exists():
            return summary
            
        try:
            lines = []
            with open(ledger, "r") as f:
                lines = f.readlines()
                
            summary["total_decisions"] = len(lines)
            denials = {}
            
            for line in lines:
                try:
                    entry = json.loads(line)
                    if entry.get("policy_decision") == "ALLOW":
                        summary["allow_count"] += 1
                    else:
                        summary["deny_count"] += 1
                        for r in entry.get("deny_reason", []):
                            denials[r] = denials.get(r, 0) + 1
                    
                    # Keep last one
                    summary["last_decision"] = f"{entry.get('policy_decision')} ({entry.get('suggested_playbook')})"
                except: pass
                
            # Rank denials
            sorted_denials = sorted(denials.items(), key=lambda x: x[1], reverse=True)
            summary["top_deny_reasons"] = [f"{k} ({v})" for k, v in sorted_denials[:3]]
            
        except Exception as e:
            summary["error"] = str(e)
            
        return summary
    @staticmethod
    def _get_latest_runtime_patch() -> Optional[Dict[str, Any]]:
        """
        Retrieves the most recent EXECUTED_RUNTIME_PATCH from the ledger.
        """
        root = get_artifacts_root()
        ledger = root / "runtime/shadow_repair/shadow_repair_ledger.jsonl"
        if not ledger.exists(): return None
        
        last_patch = None
        try:
            with open(ledger, "r") as f:
                for line in f:
                    if not line.strip(): continue
                    try:
                        entry = json.loads(line)
                        if entry.get("action") == "EXECUTED_RUNTIME_PATCH":
                            last_patch = entry
                    except: pass
        except: pass
        return last_patch
        return last_patch

    @staticmethod
    def _get_immune_status(root) -> Dict[str, Any]:
        """
        Day 32: Immune System Snapshot.
        """
        path = root / "runtime/immune/immune_snapshot.json"
        if path.exists():
            try:
                with open(path, "r") as f:
                    return json.load(f)
            except: pass
        return {"status": "NOT_FOUND"}

    @staticmethod
    def _get_black_box_status() -> Dict[str, Any]:
        """
        Day 34: Black Box Panel.
        """
        from backend.os_ops.black_box import BlackBox
        return BlackBox.verify_integrity()

    @staticmethod
    def _get_dojo_status(root) -> Dict[str, Any]:
        """
        Day 33: Dojo Panel.
        """
        path = root / "runtime/dojo/dojo_simulation_report.json"
        if path.exists():
            try:
                with open(path, "r") as f:
                    return json.load(f)
            except: pass
        return {"status": "NOT_FOUND"}

    @staticmethod
    def _get_tuning_status(root) -> Dict[str, Any]:
        """
        Day 33.1: Tuning Gate Panel.
        """
        path = root / "runtime/tuning/applied_thresholds.json"
        
        status = {
            "applied_active": False,
            "latest_proposal": "NONE",
            "active_overrides": []
        }
        
        # 1. Check Applied
        if path.exists():
             try:
                 with open(path, "r") as f:
                     data = json.load(f)
                     status["applied_active"] = True
                     status["active_overrides"] = list(data.get("overrides", {}).keys())
                     status["latest_proposal"] = data.get("meta", {}).get("proposal_id", "UNKNOWN")
             except: pass
             
        # 2. Check Ledger for last decision if not active
        if not status["applied_active"]:
             ledger = root / "runtime/tuning/tuning_ledger.jsonl"
             if ledger.exists():
                 try:
                     with open(ledger, "r") as f:
                         lines = f.readlines()
                         if lines:
                             last = json.loads(lines[-1])
                             status["last_decision"] = last.get("status")
                             status["latest_proposal"] = last.get("proposal_id")
                 except: pass
                 
        return status
