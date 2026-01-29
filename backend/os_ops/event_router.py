
import json
import datetime
from typing import Dict, Any, List

from backend.artifacts.io import append_to_ledger, get_artifacts_root

class EventRouter:
    """
    D48.BRAIN.06: Centralized System Event Router.
    Coordination and Notification Bus for OS Events.
    Append-Only Ledger: outputs/ledgers/system_events.jsonl
    """
    
    LEDGER_PATH = "ledgers/system_events.jsonl"
    
    SEVERITY_INFO = "INFO"
    SEVERITY_WARN = "WARN"
    SEVERITY_ERROR = "ERROR"
    SEVERITY_CRITICAL = "CRITICAL"
    
    @staticmethod
    def emit(event_type: str, severity: str, details: Dict[str, Any], symbol: str = None, timeframe: str = None):
        """
        Emits a system event to the ledger.
        Non-blocking (best effort).
        """
        try:
            entry = {
                "timestamp_utc": datetime.datetime.utcnow().isoformat(),
                "event_type": event_type,
                "severity": severity,
                "symbol": symbol,
                "timeframe": timeframe,
                "details": details,
                "version": "1.0"
            }
            append_to_ledger(EventRouter.LEDGER_PATH, entry)
        except Exception as e:
            # Failsafe: Never crash the caller.
            print(f"[EventRouter] Emit Failed: {e}")

    @staticmethod
    def get_latest(limit: int = 50) -> List[Dict[str, Any]]:
        """
        Returns the tail of the event ledger.
        """
        ledger_path = get_artifacts_root() / EventRouter.LEDGER_PATH
        if not ledger_path.exists():
            return []
            
        lines = []
        try:
            with open(ledger_path, "r", encoding="utf-8") as f:
                # Read strict lines
                for line in f:
                    try:
                        lines.append(json.loads(line))
                    except: pass
            
            return lines[-limit:]
        except Exception:
            return []
