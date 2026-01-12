from datetime import datetime
import pytz

def get_now_et() -> datetime:
    """Returns current time in America/New_York."""
    # Day 03: Strict Timezone Logic
    tz = pytz.timezone('America/New_York')
    return datetime.now(tz)

def is_weekend_et(now_et: datetime) -> bool:
    """True if Saturday (5) or Sunday (6)."""
    return now_et.weekday() >= 5
