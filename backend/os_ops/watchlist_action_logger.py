import os
import json
import re
import shutil
from typing import Optional, Dict
from pydantic import BaseModel, Field, validator
from datetime import datetime

# --- Configuration ---
LEDGER_DIR = os.path.abspath("outputs/os")
LEDGER_FILE = os.path.join(LEDGER_DIR, "watchlist_actions_ledger.jsonl")
PREV_LEDGER_FILE = os.path.join(LEDGER_DIR, "watchlist_actions_ledger.prev.jsonl")
MAX_SIZE_BYTES = 256 * 1024  # 256KB

# --- Models ---
class WatchlistActionEvent(BaseModel):
    timestamp_utc: str
    session_id: Optional[str] = None
    actor: str = Field(..., regex="^(USER|FOUNDER|SYSTEM)$")
    action: str = Field(..., regex="^(ADD|REMOVE|ANALYZE_TAP|BLOCKED_LOCKED|BLOCKED_STALE|OPENED_ON_DEMAND|RESULT_RENDERED)$")
    ticker: Optional[str] = None
    tier: str = Field(..., regex="^(FREE|PLUS|ELITE|FOUNDER)$")
    outcome: str = Field(..., regex="^(SUCCESS|BLOCKED|NO_OP)$")
    reason: Optional[str] = None
    metadata: Optional[Dict[str, str]] = None

    @validator('ticker')
    def validate_ticker(cls, v):
        if v is None:
            return v
        # Institutional Guard: Strict Ticker Format
        if not re.match(r"^[A-Z0-9._-]{1,12}$", v):
            raise ValueError(f"Invalid ticker format: {v}")
        return v

class WatchlistActionLogResult(BaseModel):
    status: str
    appended: bool
    ledger_path: str
    ledger_count_last_24h: int = 0

# --- Logic ---
def _ensure_ledger_dir():
    os.makedirs(LEDGER_DIR, exist_ok=True)

def _rotate_if_needed():
    if not os.path.exists(LEDGER_FILE):
        return

    try:
        size = os.path.getsize(LEDGER_FILE)
        if size > MAX_SIZE_BYTES:
            # Rotate
            shutil.copy2(LEDGER_FILE, PREV_LEDGER_FILE)
            # Truncate primary
            with open(LEDGER_FILE, 'w') as f:
                pass
    except Exception as e:
        print(f"ROTATION_ERROR: {e}")

def append_watchlist_log(event: WatchlistActionEvent) -> WatchlistActionLogResult:
    _ensure_ledger_dir()
    _rotate_if_needed()

    try:
        line = event.json() + "\n"
        with open(LEDGER_FILE, 'a') as f:
            f.write(line)
        
        # Simple count estimation (optional/lightweight)
        # For now we just return 0 to keep it fast, or we could scan.
        # Let's keep it O(1) for writes.
        
        return WatchlistActionLogResult(
            status="SUCCESS",
            appended=True,
            ledger_path=LEDGER_FILE
        )
    except Exception as e:
        return WatchlistActionLogResult(
            status=f"FAILED: {str(e)}",
            appended=False,
            ledger_path=LEDGER_FILE
        )

def tail_watchlist_log(lines: int = 50) -> list[str]:
    if not os.path.exists(LEDGER_FILE):
        return []
    
    # Simple tail via reading lines
    # Since file is capped at 256KB, reading all lines is safe-ish, 
    # but seek approach is better for 'tail'.
    # Given the small size cap, readlines() is acceptable for MVP simplicity 
    # and "Institutional Read-Only Safe" compliance (no complex seeking).
    try:
        with open(LEDGER_FILE, 'r') as f:
            all_lines = f.readlines()
            return [l.strip() for l in all_lines[-lines:]]
    except:
        return []
