import json
from datetime import datetime, timezone
from typing import Dict, Any
from backend.artifacts.io import get_artifacts_root

class RollbackLedger:
    """
    D41.05: OS Rollback Intent Ledger.
    Logs all rollback attempts (Founder actions), successful or not.
    """
    LEDGER_PATH = "os/os_rollback_intent_ledger.jsonl"

    @staticmethod
    def log_intent(
        actor: str,
        action: str,
        target_lkg_hash: str,
        result: str,
        reason: str
    ) -> Dict[str, Any]:
        """
        Appends a new entry to the ledger.
        """
        root = get_artifacts_root()
        path = root / RollbackLedger.LEDGER_PATH
        
        # Ensure parent dir exists
        path.parent.mkdir(parents=True, exist_ok=True)
        
        entry = {
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "actor": actor,
            "action": action,
            "target_lkg_hash": target_lkg_hash,
            "result": result,
            "reason": reason
        }
        
        # Append
        try:
            with open(path, "a", encoding="utf-8") as f:
                f.write(json.dumps(entry) + "\n")
        except Exception:
            pass
            
        return entry
