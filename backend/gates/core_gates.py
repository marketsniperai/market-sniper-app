from datetime import datetime, timezone, timedelta
from typing import Optional, List, Tuple

def check_stale(timestamp_str: Optional[str], threshold_hours: float = 2.0) -> Tuple[bool, List[str]]:
    """
    Checks if a timestamp is older than threshold_hours.
    Returns (is_passed, reasons).
    """
    if not timestamp_str:
        return False, ["TIMESTAMP_MISSING"]
        
    try:
        # Handle ISO format with Z or offset
        ts = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        
        diff = now - ts
        if diff > timedelta(hours=threshold_hours):
            return False, [f"DATA_STALE_AGE_{diff.total_seconds() / 3600:.1f}H"]
            
        return True, []
        
    except Exception as e:
        return False, [f"TIMESTAMP_INVALID: {str(e)}"]

def run_core_gates(manifest_data: dict) -> dict:
    """
    Runs minimal contract gates.
    """
    reasons = []
    
    # 1. Stale Check
    passed, stale_reasons = check_stale(manifest_data.get("timestamp"))
    if not passed:
        reasons.extend(stale_reasons)
        
    status = "PASSED" if not reasons else "DEGRADED"
    
    return {
        "gate_status": status,
        "reasons": reasons
    }
