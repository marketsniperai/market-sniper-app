import json
import hashlib
import os
import uuid
import logging
import traceback
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List, Optional

# Setup Logger - Fail Safe
logger = logging.getLogger("OS.Ops.BlackBox")
logger.setLevel(logging.INFO)

class BlackBox:
    """
    OS.Ops.BlackBox (Day 34)
    Forensic Indestructibility.
    Records events in an immutable hash chain. Captures crash snapshots.
    """
    
    CONTRACT_PATH = Path("os_black_box_contract.json")
    OUTPUT_ROOT = Path("backend/outputs/runtime/black_box")
    LEDGER_PATH = OUTPUT_ROOT / "decision_ledger.jsonl"
    SNAPSHOT_DIR = OUTPUT_ROOT / "crash_snapshots"
    
    _last_hash = "GENESIS_DAY_34" # In-memory cache of last hash to optimize
    
    @classmethod
    def _init_storage(cls):
        cls.OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
        cls.SNAPSHOT_DIR.mkdir(parents=True, exist_ok=True)
        
        # Recover last hash if ledger exists
        if cls.LEDGER_PATH.exists():
            try:
                # Read last line efficiently
                with open(cls.LEDGER_PATH, 'rb') as f:
                    try:  # Handle empty file case
                        f.seek(-2, os.SEEK_END)
                        while f.read(1) != b'\n':
                            f.seek(-2, os.CUR)
                    except OSError:
                        f.seek(0)
                        
                    last_line = f.readline().decode()
                    if last_line.strip():
                        entry = json.loads(last_line)
                        cls._last_hash = entry.get("current_hash", cls._last_hash)
            except Exception:
                # If fail to read last line, we might break chain or reset.
                # For safety, we treat as GENESIS if corrupt, but log error.
                pass

    @classmethod
    def record_event(cls, event_type: str, payload: Dict[str, Any], context: Dict[str, Any] = None):
        """
        Public Hook: Record an event to the ledger.
        NEVER throws exception to caller (Fail Safe).
        """
        try:
            cls._init_storage()
            
            # 1. Sanitize
            clean_payload = cls.sanitize(payload)
            clean_context = cls.sanitize(context) if context else {}
            
            # 2. Prepare Entry
            timestamp = datetime.now(timezone.utc).isoformat()
            event_id = str(uuid.uuid4())
            
            # 3. Compute Hash
            # Hash(PrevHash + EventType + Timestamp + PayloadStr)
            payload_str = json.dumps(clean_payload, sort_keys=True)
            hasher = hashlib.sha256()
            hasher.update(cls._last_hash.encode('utf-8'))
            hasher.update(event_type.encode('utf-8'))
            hasher.update(timestamp.encode('utf-8'))
            hasher.update(payload_str.encode('utf-8'))
            current_hash = hasher.hexdigest()
            
            entry = {
                "event_id": event_id,
                "timestamp": timestamp,
                "event_type": event_type,
                "prev_hash": cls._last_hash,
                "current_hash": current_hash,
                "payload": clean_payload,
                "context": clean_context
            }
            
            # 4. Append to Ledger
            with open(cls.LEDGER_PATH, "a") as f:
                f.write(json.dumps(entry) + "\n")
                
            # 5. Update Memory
            cls._last_hash = current_hash
            
        except Exception as e:
            # Non-Interference Law: Do NOT crash the caller.
            # But try to log to fallback
            logger.error(f"BlackBox Write Failure: {e}")

    @classmethod
    def snapshot(cls, system_state: Dict[str, Any] = None, reason: str = "UNKNOWN"):
        """
        Trigger a Crash Snapshot.
        """
        try:
            cls._init_storage()
            timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
            filename = f"CRASH_{timestamp}.json"
            path = cls.SNAPSHOT_DIR / filename
            
            clean_state = cls.sanitize(system_state) if system_state else {}
            
            snapshot_data = {
                "timestamp_utc": datetime.now(timezone.utc).isoformat(),
                "reason": reason,
                "ledger_tail_hash": cls._last_hash,
                "system_state_dump": clean_state
            }
            
            with open(path, "w") as f:
                json.dump(snapshot_data, f, indent=2)
                
            return str(path)
        except Exception as e:
            logger.error(f"BlackBox Snapshot Failure: {e}")
            return None

    @classmethod
    def sanitize(cls, data: Any) -> Any:
        """
        Deep sanitization of dicts/lists.
        Removes forbidden keys. Truncates long strings/arrays.
        """
        FORBIDDEN = {"api_key", "secret", "token", "password", "x-founder-key", "auth", "credential"}
        MAX_STR = 1000
        MAX_ARR = 50
        
        if isinstance(data, dict):
            new_dict = {}
            for k, v in data.items():
                # Key Check
                if any(bad in k.lower() for bad in FORBIDDEN):
                    new_dict[k] = "***REDACTED***"
                else:
                    new_dict[k] = cls.sanitize(v)
            return new_dict
        
        elif isinstance(data, list):
            if len(data) > MAX_ARR:
                return [cls.sanitize(x) for x in data[:MAX_ARR]] + [f"...TRUNCATED {len(data)-MAX_ARR} ITEMS..."]
            return [cls.sanitize(x) for x in data]
            
        elif isinstance(data, str):
            if len(data) > MAX_STR:
                return data[:MAX_STR] + "...(TRUNCATED)"
            return data
            
        else:
            return data

    @classmethod
    def get_ledger_tail(cls, limit=50) -> List[Dict]:
        """Read-Only Accessor"""
        if not cls.LEDGER_PATH.exists(): return []
        try:
            with open(cls.LEDGER_PATH, "r") as f:
                lines = f.readlines()
                return [json.loads(line) for line in lines[-limit:]]
        except:
            return []

    @classmethod
    def verify_integrity(cls) -> Dict[str, Any]:
        """
        Verifies the hash chain from start to finish.
        Returns check result.
        """
        if not cls.LEDGER_PATH.exists():
            return {"status": "EMPTY", "valid": True}
            
        computed_last = "GENESIS_DAY_34"
        broken_at = -1
        count = 0
        
        try:
            with open(cls.LEDGER_PATH, "r") as f:
                for idx, line in enumerate(f):
                    if not line.strip(): continue
                    entry = json.loads(line)
                    count += 1
                    
                    # Check prev hash link
                    if entry["prev_hash"] != computed_last:
                        return {"status": "BROKEN_LINK", "valid": False, "index": idx}
                        
                    # Recompute current hash
                    payload_str = json.dumps(entry["payload"], sort_keys=True)
                    hasher = hashlib.sha256()
                    hasher.update(computed_last.encode('utf-8'))
                    hasher.update(entry["event_type"].encode('utf-8'))
                    hasher.update(entry["timestamp"].encode('utf-8'))
                    hasher.update(payload_str.encode('utf-8'))
                    recalc_hash = hasher.hexdigest()
                    
                    if recalc_hash != entry["current_hash"]:
                        return {"status": "TAMPERED_CONTENT", "valid": False, "index": idx}
                        
                    computed_last = recalc_hash
                    
            return {"status": "OK", "valid": True, "count": count, "head_hash": computed_last}
            
        except Exception as e:
            return {"status": "ERROR", "valid": False, "details": str(e)}
