
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
    
    # D49 Elite Events
    # D49 Elite Events
    EVENT_ELITE_RITUAL_AVAILABLE = "ELITE_RITUAL_AVAILABLE"
    EVENT_ELITE_RITUAL_CLOSING = "ELITE_RITUAL_CLOSING"
    EVENT_ELITE_FREE_WINDOW_OPEN = "ELITE_FREE_WINDOW_OPEN"
    EVENT_ELITE_FREE_WINDOW_CLOSING = "ELITE_FREE_WINDOW_CLOSING"
    
    # Prompt 10 Extensions
    EVENT_ELITE_BRIEFING_READY = "ELITE_BRIEFING_READY"
    EVENT_ELITE_MIDDAY_READY = "ELITE_MIDDAY_READY"
    EVENT_ELITE_MARKET_SUMMARY_READY = "ELITE_MARKET_SUMMARY_READY"
    EVENT_ELITE_FREE_WINDOW_5MIN = "ELITE_FREE_WINDOW_5MIN"
    EVENT_ELITE_FREE_WINDOW_CLOSED = "ELITE_FREE_WINDOW_CLOSED" # Explicit closed event
    
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
    def get_latest(limit: int = 50, since_timestamp: str = None) -> List[Dict[str, Any]]:
        """
        Returns the tail of the event ledger.
        Optionally filters by timestamp > since_timestamp (ISO format).
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
                        entry = json.loads(line)
                        if since_timestamp:
                            if entry.get("timestamp_utc", "") > since_timestamp:
                                lines.append(entry)
                        else:
                            lines.append(entry)
                    except: pass
            
            # If filtering by timestamp, we trust correct order, so just return all found.
            # If no timestamp, return last N.
            if since_timestamp:
                return lines # Return all new events
            else:
                return lines[-limit:]
        except Exception:
            return []
