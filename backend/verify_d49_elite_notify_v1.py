
import os
import sys
import json
import datetime

sys.path.append(os.getcwd())
from backend.os_ops.event_router import EventRouter

def verify_notification_events():
    print("--- Verifying Elite Notification Events ---")
    
    events = [
        (EventRouter.EVENT_ELITE_BRIEFING_READY, "INFO"),
        (EventRouter.EVENT_ELITE_MIDDAY_READY, "INFO"),
        (EventRouter.EVENT_ELITE_MARKET_SUMMARY_READY, "INFO"),
        (EventRouter.EVENT_ELITE_FREE_WINDOW_OPEN, "INFO"),
        (EventRouter.EVENT_ELITE_FREE_WINDOW_5MIN, "WARN"),
        (EventRouter.EVENT_ELITE_FREE_WINDOW_CLOSED, "INFO"),
    ]
    
    for evt, sev in events:
        print(f"Emitting {evt}...")
        EventRouter.emit(evt, sev, {"test": True})
        
    print("Events emitted. Checking ledger tail...")
    
    latest = EventRouter.get_latest(limit=len(events))
    
    # Verify latest match
    found_types = [x['event_type'] for x in latest]
    
    for evt, _ in events:
        if evt not in found_types:
            print(f"FAILURE: Event {evt} not found in ledger.")
            sys.exit(1)
            
    print("SUCCESS: All notification events logged.")

if __name__ == "__main__":
    verify_notification_events()
