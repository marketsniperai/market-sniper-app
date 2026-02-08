import json
from datetime import datetime, timedelta

# Mock Logic matching Dart Service
def is_market_open_day(date):
    # Mon=0, Sun=6. In Dart Mon=1, Sun=7.
    # Logic: Weekday >= 1 (Mon) && <= 5 (Fri). 
    # Python weekday(): Mon=0, Fri=4.
    return 0 <= date.weekday() <= 4

def simulate():
    # Start: Friday
    start_date = datetime(2026, 2, 6) # Friday (Market Open)
    
    # State
    plus_days_remaining = 5
    last_stamp = None
    
    results = []
    
    # Simulate 10 days
    for i in range(10):
        current_date = start_date + timedelta(days=i)
        day_name = current_date.strftime("%A")
        stamp = current_date.strftime("%Y-%m-%d")
        
        market_open = is_market_open_day(current_date)
        decremented = False
        
        # User opens app
        if market_open:
            if last_stamp != stamp:
                if plus_days_remaining > 0:
                    plus_days_remaining -= 1
                    decremented = True
                    last_stamp = stamp
        
        results.append({
            "day": i + 1,
            "date": stamp,
            "weekday": day_name,
            "market_open": market_open,
            "app_opened": True, # Assume user opens every day
            "decremented": decremented,
            "remaining": plus_days_remaining
        })

    return results

if __name__ == "__main__":
    data = simulate()
    print(json.dumps(data, indent=2))
