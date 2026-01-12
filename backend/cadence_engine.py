from datetime import time, datetime
from backend.os_time import get_now_et, is_weekend_et

# Windows (ET)
# PREMARKET: 04:00 - 09:30
# OPEN_VOL: 09:30 - 10:30
# MIDDAY: 10:30 - 15:00
# POWER_HOUR: 15:00 - 16:00
# AFTER_HOURS: 16:00 - 20:00
# OVERNIGHT: 20:00 - 04:00

WINDOWS = [
    {"name": "PREMARKET", "start": time(4, 0), "end": time(9, 30), "mode": "FULL"},
    {"name": "OPEN_VOL", "start": time(9, 30), "end": time(10, 30), "mode": "LIGHT"},
    {"name": "MIDDAY", "start": time(10, 30), "end": time(15, 0), "mode": "LIGHT"},
    {"name": "POWER_HOUR", "start": time(15, 0), "end": time(16, 0), "mode": "LIGHT"},
    {"name": "AFTER_HOURS", "start": time(16, 0), "end": time(20, 0), "mode": "LIGHT"},
    # Overnight/Default handles the rest
]

def get_window(now_et: datetime) -> dict:
    """Returns the current market window."""
    t = now_et.time()
    
    # Simple iteration (Logic valid for Day 03 Scaffold)
    for w in WINDOWS:
        if w["start"] <= t < w["end"]:
            return w
            
    # Default / Overnight
    return {"name": "OVERNIGHT", "mode": "LIGHT", "start": time(20, 0), "end": time(4, 0)}

def resolve_run_mode(requested_mode: str) -> str:
    """Resolves 'AUTO' to actual mode based on time."""
    if requested_mode != "AUTO":
        return requested_mode
        
    now = get_now_et()
    if is_weekend_et(now):
        return "LIGHT"
        
    window = get_window(now)
    return window["mode"]
