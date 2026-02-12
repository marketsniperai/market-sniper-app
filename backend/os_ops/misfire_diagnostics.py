from backend.os_ops.misfire_root_cause_reader import MisfireRootCauseReader
from backend.os_ops.misfire_tier2_reader import MisfireTier2Reader

def get_misfire_diagnostics() -> dict:
    """
    Centralized logic to fetch deep-dive diagnostics for Misfire.
    Returns a dictionary suitable for insertion into 'misfire_report.json' under 'diagnostics'.
    """
    diag = {
         "status": "UNAVAILABLE",
         "root_cause": "UNAVAILABLE",
         "tier2_signals": [],
         "reason": "OK"
    }
    
    try:
        # Root Cause
        rc_snap = MisfireRootCauseReader.get_snapshot()
        if rc_snap:
            diag["root_cause"] = rc_snap.misfire_type
            diag["status"] = "AVAILABLE"
            diag["reason"] = "INCIDENT_CAPTURED"
        else:
            diag["reason"] = "NO_RECENT_MISFIRES"

        # Tier 2
        t2_snap = MisfireTier2Reader.get_snapshot()
        if t2_snap:
             steps_summary = []
             for s in t2_snap.steps:
                 steps_summary.append({
                     "step": s.step_id,
                     "attempted": s.attempted,
                     "result": s.result or "UNKNOWN"
                 })
             diag["tier2_signals"] = steps_summary
             diag["status"] = "AVAILABLE"
             
    except Exception as e:
        diag["reason"] = f"PARTIAL_READ_ERROR: {str(e)}"
        
    return diag
