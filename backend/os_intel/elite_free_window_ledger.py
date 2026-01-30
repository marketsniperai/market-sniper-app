
import json
import datetime
import hashlib
from typing import Dict, Any, Optional
from backend.artifacts.io import append_to_ledger

class EliteFreeWindowLedger:
    """
    D49: Ledger for Monday Free Window interactions.
    Records openings, closures, and interactions for conversion analytics.
    """
    LEDGER_PATH = "ledgers/elite_free_window_ledger.jsonl"

    @staticmethod
    def log_interaction(user_id: str, action: str, details: Optional[Dict[str, Any]] = None):
        """
        Logs a user interaction during the free window.
        Hashes user_id for privacy if needed (though request usually has it).
        """
        # Simple hash if not already anonymous, or just use as is if internal ID.
        # Assuming user_id is internal UUID, logging it is fine in internal ledger.
        
        entry = {
            "timestamp_utc": datetime.datetime.utcnow().isoformat(),
            "user_id_hash": hashlib.sha256(user_id.encode()).hexdigest(),
            "action": action, # OPEN_WINDOW, SEND_MESSAGE, CLICK_UPGRADE, CLOSE_WINDOW
            "details": details or {}
        }
        
        try:
            append_to_ledger(EliteFreeWindowLedger.LEDGER_PATH, entry)
        except Exception as e:
            print(f"[FreeWindowLedger] Log failed: {e}")
