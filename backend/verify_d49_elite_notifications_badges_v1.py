
import asyncio
import os
import sys

# Ensure backend path
sys.path.append(os.getcwd())

from backend.os_ops.event_router import EventRouter

def test_events_flow():
    print("--- 1. Cleaning up mock event... ---")
    # No cleanup needed as append-only, but we can emit a distinct one
    
    print("--- 2. Emitting Elite Event... ---")
    EventRouter.emit(
        event_type=EventRouter.EVENT_ELITE_RITUAL_AVAILABLE,
        severity=EventRouter.SEVERITY_INFO,
        details={"ritual_id": "TEST_RITUAL_01"},
        symbol="OS"
    )
    print("Event Emitted.")

    print("--- 3. Reading back events... ---")
    events = EventRouter.get_latest(limit=5)
    found = False
    for e in events:
        if e['event_type'] == EventRouter.EVENT_ELITE_RITUAL_AVAILABLE and \
           e['details'].get('ritual_id') == "TEST_RITUAL_01":
           found = True
           print(f"FOUND MATCH: {e}")
           break
    
    if found:
        print("SUCCESS: Event persisted and retrieved.")
    else:
        print("FAILURE: Event not found.")
        sys.exit(1)

if __name__ == "__main__":
    test_events_flow()
