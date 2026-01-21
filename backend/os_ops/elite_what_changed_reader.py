import json
import os
from datetime import datetime, timezone, timedelta
from typing import List, Optional
from pydantic import BaseModel

# Constants
PATH_OS_TIMELINE = "outputs/os/os_timeline.jsonl"
WINDOW_SECONDS = 300 # 5 minutes
MAX_ITEMS = 8 

class WhatChangedItem(BaseModel):
    domain: str # MARKET | OS | OVERLAY
    code: str
    message: str
    ts_utc: str

class EliteWhatChangedSnapshot(BaseModel):
    window_seconds: int
    timestamp_utc: str
    items: List[WhatChangedItem]

class EliteWhatChangedReader:
    
    def get_what_changed(self) -> Optional[EliteWhatChangedSnapshot]:
        """
        Reads the last 5 minutes of changes from OS Timeline.
        Returns None if artifact is missing (UNAVAILABLE).
        Returns empty list if no changes in window.
        """
        if not os.path.exists(PATH_OS_TIMELINE):
            # Strict mode: if the timeline artifact is missing, the service is UNAVAILABLE
            # Alternatively, if it's just empty, return empty list. 
            # D43.12 requirements say: "If unavailable -> UNAVAILABLE".
            # Missing file usually means system never ran -> Unavailable.
            return None

        items = []
        now_utc = datetime.now(timezone.utc)
        cutoff_utc = now_utc - timedelta(seconds=WINDOW_SECONDS)

        try:
            # tailored read: read from end? or just read all (assuming reasonable size)?
            # IronOS.timeline_tail reads whole file but cap limits. 
            # We must be careful with large files. 
            # For this task, we'll read lines, parse, filter.
            # Efficiency hack: Read last N lines or just read all if small. 
            # We'll stick to a safe full read (with cap safety) for now as this is a local desktop app repo.
            
            # Read lines
            with open(PATH_OS_TIMELINE, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # Process in reverse (newest first)
            for line in reversed(lines):
                if len(line) > 8192: continue # Skip huge lines
                try:
                    event = json.loads(line)
                    ts_str = event.get('ts_utc') or event.get('timestamp')
                    if not ts_str: continue

                    # Parse TS
                    try:
                        dt = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                    except:
                        continue 
                    
                    if dt < cutoff_utc:
                        # Since we read reverse, once we hit older than cutoff, we can potentially stop 
                        # IF the file is strictly ordered. It should be.
                        break 
                        
                    # Map to Item
                    # Domain logic: check event type
                    event_type = event.get('type', 'UNKNOWN')
                    domain = "OS"
                    if "MARKET" in event_type or "PRICE" in event_type:
                        domain = "MARKET"
                    elif "OVERLAY" in event_type:
                        domain = "OVERLAY"
                    
                    items.append(WhatChangedItem(
                        domain=domain,
                        code=event_type,
                        message=event.get('summary') or event.get('message') or "Event",
                        ts_utc=ts_str
                    ))
                    
                    if len(items) >= MAX_ITEMS:
                        break
                        
                except:
                    continue
                    
        except Exception as e:
            # If read fails, treat as unavailable
            return None

        return EliteWhatChangedSnapshot(
            window_seconds=WINDOW_SECONDS,
            timestamp_utc=now_utc.isoformat(),
            items=items
        )
