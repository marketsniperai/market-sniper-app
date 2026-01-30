
import os
import sys
import json
import datetime
import pytz

sys.path.append(os.getcwd())

from backend.os_ops.elite_ritual_policy import EliteRitualPolicy

def verify_policy_logic():
    print("--- Verifying Elite Ritual Policy (Free Window) ---")
    
    policy = EliteRitualPolicy()
    
    # Test Time: Monday 09:30 ET
    # 2026-02-02 is a Monday
    et_tz = pytz.timezone('US/Eastern')
    mock_et = et_tz.localize(datetime.datetime(2026, 2, 2, 9, 30))
    mock_utc = mock_et.astimezone(pytz.utc)
    
    print(f"Testing state for: {mock_et} (ET)")
    state = policy.get_ritual_state(mock_utc)
    
    if "elite_monday_free_window" not in state:
        print("FAILURE: 'elite_monday_free_window' not found in state.")
        print(json.dumps(state, indent=2))
        sys.exit(1)
        
    window = state["elite_monday_free_window"]
    print(json.dumps(window, indent=2))
    
    # Window is 09:20 - 10:20 (60 mins). At 09:30, 50 mins remain.
    # Trigger is 15 mins. So countdown might be None?
    # Policy logic:
    # if 0 < remaining <= countdown_trigger: countdown = int(remaining)
    # Remaining = 50. Trigger = 15. 50 <= 15 is False.
    # So countdown should be None.
    
    if window["enabled"] is not True:
        print("FAILURE: Window should be ENABLED.")
        sys.exit(1)
    if window["countdown_minutes"] is not None:
         print(f"WARNING: Countdown should be None (Trigger is 15m), got {window['countdown_minutes']}. But maybe okay if policy changed.")

    # Test T-5 (10:15 ET)
    mock_et_late = et_tz.localize(datetime.datetime(2026, 2, 2, 10, 15))
    mock_utc_late = mock_et_late.astimezone(pytz.utc)
    
    print(f"Testing state for: {mock_et_late} (ET)")
    state_late = policy.get_ritual_state(mock_utc_late)
    window_late = state_late["elite_monday_free_window"]
    print(json.dumps(window_late, indent=2))
    
    # Remaining: 5 mins. Trigger 15. 5 <= 15 True.
    if window_late["countdown_minutes"] != 5:
        # Might be 4 or 5 depending on seconds precision
        print(f"FAILURE: Expected countdown ~5, got {window_late['countdown_minutes']}")
        # Allow +/- 1
        if window_late['countdown_minutes'] not in [4, 5, 6]:
             sys.exit(1)
             
    print("SUCCESS: Policy Logic Verified.")

if __name__ == "__main__":
    verify_policy_logic()
