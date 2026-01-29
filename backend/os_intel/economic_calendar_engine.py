import datetime
import random
from typing import Dict, Any, List
from backend.artifacts.io import atomic_write_json, get_artifacts_root

class EconomicCalendarEngine:
    """
    D47.HF35: Economic Calendar Engine (Demo/Deterministic).
    
    Generates high-fidelity demo data for the Economic Calendar
    until a real provider pipeline is established.
    
    Principles:
    1. Deterministic: Same date = Same events.
    2. High-Fidelity: Real event names (CPI, FOMC, NFP).
    3. Artifact-First: Produces `economic_calendar.json`.
    """
    
    VERSION = "1.0.0"
    ARTIFACT_PATH = "engine/economic_calendar.json"
    
    @staticmethod
    def generate_and_persist(as_of_utc: datetime.datetime = None) -> Dict[str, Any]:
        """
        Generates demo calendar data and saves to artifact.
        """
        if as_of_utc is None:
            as_of_utc = datetime.datetime.utcnow()
            
        data = EconomicCalendarEngine.generate_demo_calendar(as_of_utc)
        
        # Persist
        root = get_artifacts_root()
        path = root / EconomicCalendarEngine.ARTIFACT_PATH
        path.parent.mkdir(parents=True, exist_ok=True)
        atomic_write_json(str(path), data)
        
        return data

    @staticmethod
    def generate_demo_calendar(as_of_utc: datetime.datetime) -> Dict[str, Any]:
        """
        Creates a list of mock events for the next 14 days.
        """
        events = []
        
        # Seed random with current date (day resolution) for stability
        # We want the calendar to look "stable" if refreshed today.
        seed_val = int(as_of_utc.strftime("%Y%m%d"))
        rng = random.Random(seed_val)
        
        # Event definitions
        macro_events = [
            ("CPI (YoY)", "HIGH", ["inflation", "rates"]),
            ("PPI (MoM)", "MEDIUM", ["inflation"]),
            ("Non-Farm Payrolls", "HIGH", ["jobs", "growth"]),
            ("FOMC Rate Decision", "HIGH", ["rates", "fed"]),
            ("Retail Sales", "MEDIUM", ["consumer", "growth"]),
            ("GDP Growth (QoQ)", "HIGH", ["growth"]),
            ("Fed Chair Powell Speaks", "HIGH", ["fed", "volatility"]),
            ("Initial Jobless Claims", "MEDIUM", ["jobs"]),
            ("Consumer Sentiment", "LOW", ["consumer"])
        ]
        
        earnings_events = [
            ("AAPL Earnings", "HIGH", ["tech", "earnings"]),
            ("NVDA Earnings", "HIGH", ["ai", "semi"]),
            ("TSLA Earnings", "HIGH", ["auto", "volatility"]),
            ("MSFT Earnings", "MEDIUM", ["tech", "cloud"]),
            ("AMD Earnings", "MEDIUM", ["semi"]),
            ("JPM Earnings", "LOW", ["banks"])
        ]
        
        # Generate 2-3 events per day for next 14 days
        for i in range(14):
            day = as_of_utc + datetime.timedelta(days=i)
            # Skip weekends for "major" news usually, but crypto happens. 
            # Let's keep it simple: Mon-Fri mostly.
            if day.weekday() > 4: 
                continue
                
            daily_seed = seed_val + i
            day_rng = random.Random(daily_seed)
            
            num_events = day_rng.randint(1, 3)
            
            for _ in range(num_events):
                is_macro = day_rng.random() > 0.3
                if is_macro:
                    evt = day_rng.choice(macro_events)
                    cat = "MACRO"
                else:
                    evt = day_rng.choice(earnings_events)
                    cat = "EARNINGS"
                
                # Random time between 8:30 AM and 2:00 PM ET (approx)
                # We store UTC. ET is UTC-5 (or -4). 
                # 8:30 ET = 13:30 UTC.
                hour_offset = day_rng.randint(13, 19)
                minute_offset = day_rng.choice([0, 15, 30, 45])
                
                ts = day.replace(hour=hour_offset, minute=minute_offset, second=0, microsecond=0)
                
                events.append({
                    "id": f"evt_{daily_seed}_{day_rng.randint(1000,9999)}",
                    "title": evt[0],
                    "timeUtc": ts.isoformat(),
                    "category": cat,
                    "impact": evt[1],
                    "source": "DEMO_PIPE",
                    "tags": evt[2]
                })

        # Sort by time
        events.sort(key=lambda x: x["timeUtc"])
        
        return {
            "status": "OK",
            "asOfUtc": as_of_utc.isoformat(),
            "source": "DEMO_ENGINE",
            "windowDays": 14,
            "events": events
        }

if __name__ == "__main__":
    # Test generation
    import json
    data = EconomicCalendarEngine.generate_and_persist()
    print(json.dumps(data, indent=2))
