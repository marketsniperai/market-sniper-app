import json
import os
from datetime import datetime, timezone
from typing import List, Dict, Optional, Any
from backend.artifacts.io import get_artifacts_root

class ReplayArchive:
    """
    D41.04: Replay Archive Store (OS.R2.1).
    Bounded local storage (JSONL) for replay runs.
    """
    ARCHIVE_PATH = "runtime/os_replay_archive.jsonl"
    MAX_ENTRIES = 30

    @staticmethod
    def append_entry(
        day_id: str,
        status: str,
        summary: str,
        proof_pointer: str = "N/A"
    ) -> Dict[str, Any]:
        """
        Appends a new entry to the archive.
        Enforces MAX_ENTRIES bound (FIFO).
        """
        root = get_artifacts_root()
        path = root / ReplayArchive.ARCHIVE_PATH
        
        # Ensure parent dir exists
        path.parent.mkdir(parents=True, exist_ok=True)
        
        entry = {
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "day_id": day_id,
            "status": status,
            "summary": summary,
            "proof_pointer": proof_pointer
        }
        
        # Read existing
        lines = []
        if path.exists():
            try:
                with open(path, "r", encoding="utf-8") as f:
                    lines = f.readlines()
            except Exception:
                lines = [] # corrupted? start over
        
        # Append new log line
        import json
        lines.append(json.dumps(entry) + "\n")
        
        # Prune if needed (Keep last N)
        if len(lines) > ReplayArchive.MAX_ENTRIES:
             lines = lines[-ReplayArchive.MAX_ENTRIES:]
             
        # Write back
        try:
            with open(path, "w", encoding="utf-8") as f:
                f.writelines(lines)
        except Exception:
            pass # Fail safe
            
        return entry

    @staticmethod
    def get_tail(limit: int = 30) -> List[Dict[str, Any]]:
        """
        Returns last N entries (reverse chronological).
        """
        root = get_artifacts_root()
        path = root / ReplayArchive.ARCHIVE_PATH
        
        if not path.exists():
            return []
            
        entries = []
        try:
            with open(path, "r", encoding="utf-8") as f:
                lines = f.readlines()
                
            for line in reversed(lines):
                if len(entries) >= limit: break
                try:
                    entries.append(json.loads(line))
                except: continue
        except Exception:
            return []
            
        return entries
