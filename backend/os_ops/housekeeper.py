import os
import json
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Dict, List, Any
import re
import shutil

from backend.artifacts.io import get_artifacts_root, atomic_write_json, safe_read_or_fallback

HOUSEKEEPER_SUBDIR = "runtime/housekeeper"

class Housekeeper:
    """
    Day 17: OS Housekeeper.
    Scans for operational trash (.tmp, .bak, orphan locks), detects drift,
    and performs safe cleanup.
    """
    
    @staticmethod
    def scan() -> Dict[str, Any]:
        """
        Scans artifacts root for garbage and drift.
        Returns a classified inventory.
        """
        root = get_artifacts_root()
        now = datetime.now(timezone.utc)
        
        candidates = []
        drift_warnings = []
        
        # 1. File Scan (Recursive)
        # Walk output directory. 
        # Safety: We limit depth/scope implicitly by being in output dir, but let's be careful.
        for dirpath, dirnames, filenames in os.walk(root):
            for f in filenames:
                full_path = Path(dirpath) / f
                rel_path = full_path.relative_to(root)
                
                # A. Temp/Bak Files
                if f.endswith(".tmp") or f.endswith(".bak"):
                    # Check age
                    stat = full_path.stat()
                    mtime = datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc)
                    age_seconds = (now - mtime).total_seconds()
                    
                    status = "SAFE_TO_CLEAN" if age_seconds > 3600 else "RECENT_TEMP"
                    
                    candidates.append({
                        "path": str(rel_path),
                        "type": "FILE_TRASH",
                        "reason": f"Extension {full_path.suffix}",
                        "age_seconds": age_seconds,
                        "status": status
                    })
                    
                # B. Orphan Locks (os_lock.json)
                elif f == "os_lock.json":
                    # Parse lock content to see timestamp
                    try:
                        with open(full_path, "r") as lock_f:
                            data = json.load(lock_f)
                            ts_str = data.get("timestamp_utc")
                            if ts_str:
                                ts = datetime.fromisoformat(ts_str)
                                if ts.tzinfo is None: ts = ts.replace(tzinfo=timezone.utc)
                                age_seconds = (now - ts).total_seconds()
                                
                                if age_seconds > 3600: # 1h
                                    candidates.append({
                                        "path": str(rel_path),
                                        "type": "ORPHAN_LOCK",
                                        "reason": "Lock > 1h",
                                        "age_seconds": age_seconds,
                                        "status": "SAFE_TO_CLEAN"
                                    })
                    except:
                        # Corrupt lock?
                        candidates.append({
                            "path": str(rel_path),
                            "type": "ORPHAN_LOCK",
                            "reason": "Corrupt/Unreadable Lock",
                            "age_seconds": 99999,
                            "status": "REQUIRES_ATTENTION" 
                        })

                # C. Runtime Evidence Trash (Hygiene)
                # Rules: outputs/runtime/, >7 days, matching patterns
                elif str(rel_path).replace("\\", "/").startswith("runtime/"):
                    # Check age (7 days)
                    stat = full_path.stat()
                    mtime = datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc)
                    age_days = (now - mtime).total_seconds() / 86400
                    
                    if age_days > 7:
                        # Check patterns
                        # day_*_retry*, *_poll_*, *_logs_*, *_dump_*, *_snapshot_*
                        is_trash = False
                        if f.startswith("day_") and "_retry" in f: is_trash = True
                        if "_poll_" in f: is_trash = True
                        if "_logs_" in f: is_trash = True
                        if "_dump_" in f: is_trash = True
                        if "_snapshot_" in f: is_trash = True
                        
                        if is_trash:
                            candidates.append({
                                "path": str(rel_path),
                                "type": "RUNTIME_EVIDENCE_TRASH",
                                "reason": "Old Runtime Artifact > 7d",
                                "age_seconds": (now - mtime).total_seconds(),
                                "status": "SAFE_TO_QUARANTINE"
                            })

        # 2. Drift Detection
        # Check if runtime manifest timestamp aligns with expected freshness
        # This is a simplified drift check: Full Manifest Age vs Ledger
        # For now, let's checking known manifests exist.
        for m_path in ["full/run_manifest.json", "light/run_manifest.json"]:
             p = root / m_path
             if not p.exists():
                 drift_warnings.append(f"Missing critical manifest: {m_path}")
        
        # Summarize
        cleanable_count = sum(1 for c in candidates if c["status"] == "SAFE_TO_CLEAN")
        overall_status = "CLEAN"
        if cleanable_count > 0:
            overall_status = "GARBAGE_FOUND"
        if drift_warnings:
             overall_status = "DRIFT_DETECTED"
             
        scan_report = {
            "timestamp_utc": now.isoformat(),
            "overall_status": overall_status,
            "candidates": candidates,
            "drift_warnings": drift_warnings,
            "scan_id": hashlib.md5(now.isoformat().encode()).hexdigest()[:8]
        }
        
        # Persist Scan Report
        scan_path = f"{HOUSEKEEPER_SUBDIR}/housekeeper_scan.json"
        
        # Ensure dir
        os.makedirs(root / HOUSEKEEPER_SUBDIR, exist_ok=True)
        atomic_write_json(scan_path, scan_report)
        
        return scan_report

    @staticmethod
    def execute_clean(founder_key: str) -> Dict[str, Any]:
        """
        Executes cleanup based on fresh scan.
        """
        scan = Housekeeper.scan()
        executed_actions = []
        root = get_artifacts_root()
        
        for item in scan["candidates"]:
            if item["status"] == "SAFE_TO_CLEAN":
                target = root / item["path"]
                if target.exists():
                    try:
                        os.remove(target)
                        executed_actions.append({
                            "path": item["path"],
                            "result": "DELETED",
                            "type": item["type"]
                        })
                    except Exception as e:
                         executed_actions.append({
                            "path": item["path"],
                            "result": "FAILED",
                            "error": str(e)
                        })
            
            elif item["status"] == "SAFE_TO_QUARANTINE":
                target = root / item["path"]
                if target.exists():
                    try:
                        # Move to runtime/_quarantine_trash
                        q_dir = root / "runtime" / "_quarantine_trash"
                        os.makedirs(q_dir, exist_ok=True)
                        
                        # Handle name collision
                        dest_name = target.name
                        dest_path = q_dir / dest_name
                        counter = 1
                        while dest_path.exists():
                             dest_path = q_dir / f"{target.stem}_{counter}{target.suffix}"
                             counter += 1
                             
                        shutil.move(str(target), str(dest_path))
                        
                        executed_actions.append({
                            "path": item["path"],
                            "result": "QUARANTINED",
                            "dest": str(dest_path.relative_to(root)),
                            "type": item["type"]
                        })
                    except Exception as e:
                         executed_actions.append({
                            "path": item["path"],
                            "result": "FAILED",
                            "error": str(e)
                        })
        
        # Ledger Update
        report = {
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "scan_id": scan["scan_id"],
            "items_cleaned": len(executed_actions),
            "details": executed_actions
        }
        
        Housekeeper._start_ledger(report)
        
        return report

    @staticmethod
    def _start_ledger(entry: Dict[str, Any]):
        root = get_artifacts_root()
        ledger_path = root / HOUSEKEEPER_SUBDIR / "housekeeper_ledger.jsonl"
        
        with open(ledger_path, "a") as f:
            f.write(json.dumps(entry) + "\n")
            
import hashlib
