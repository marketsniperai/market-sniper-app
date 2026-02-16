import os
import json
import time
import requests
import datetime
from pathlib import Path
from typing import Dict, Any, Optional, List

# D62: Alpha Vantage Client - Batch Only, Rate Limited, Ledger Controlled

class AlphaVantageClient:
    """
    D62 Spec:
    - 5 Requests Per Minute (RPM) hard limit.
    - Daily Budget: 500 API calls (Free Tier safety).
    - Batch-Only: Prefers TIME_SERIES_DAILY or similar large payloads.
    - Fail-Safe: Returns empty dict on error/limit, never crashes.
    """
    
    BASE_URL = "https://www.alphavantage.co/query"
    LEDGER_PATH = Path("outputs/os/ledger/alpha_vantage_ledger.json")
    RPM_LIMIT = 5
    DAILY_LIMIT = 500
    
    _last_request_time = 0.0
    _request_count_minute = 0
    _minute_start_time = 0.0

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.environ.get("ALPHA_VANTAGE_KEY")
        if not self.api_key:
            print("[AV] WARNING: No API Key found. Client disabled.")

    def fetch_daily_adjusted(self, symbol: str) -> Dict[str, Any]:
        """
        Fetches TIME_SERIES_DAILY_ADJUSTED for a symbol.
        Subject to ledger and rate limits.
        """
        if not self.api_key:
            return {}

        if not self._check_budget():
             print(f"[AV] BLOCKED: Daily budget exceeded for {symbol}")
             return {}

        self._enforce_rate_limit()

        params = {
            "function": "TIME_SERIES_DAILY_ADJUSTED",
            "symbol": symbol,
            "apikey": self.api_key,
            "outputsize": "compact" # "full" for history, "compact" for last 100
        }
        
        try:
            print(f"[AV] Fetching Daily Adjusted for {symbol}...")
            response = requests.get(self.BASE_URL, params=params, timeout=10)
            
            self._update_ledger(symbol, "TIME_SERIES_DAILY_ADJUSTED")
            
            if response.status_code == 200:
                data = response.json()
                if "Note" in data:
                     print(f"[AV] LIMIT HIT (API): {data['Note']}")
                     return {}
                if "Error Message" in data:
                     print(f"[AV] ERROR: {data['Error Message']}")
                     return {}
                return data
            else:
                print(f"[AV] HTTP ERROR: {response.status_code}")
                return {}
                
        except Exception as e:
            print(f"[AV] EXCEPTION: {e}")
            return {}

    def _enforce_rate_limit(self):
        """
        Sleeps if > 5 reqs in last 60s.
        Implementation: Simple sliding window or fixed window?
        Spec says: 5 RPM.
        Let's use a simple localized tracker since this is likely running in a single job.
        """
        now = time.time()
        
        # Reset window if > 60s passed
        if now - self._minute_start_time > 60:
            self._minute_start_time = now
            self._request_count_minute = 0
            
        if self._request_count_minute >= self.RPM_LIMIT:
            # Sleep until window resets
            sleep_time = 60 - (now - self._minute_start_time) + 1
            print(f"[AV] Rate Limit (Local): Sleeping {sleep_time:.1f}s...")
            time.sleep(sleep_time)
            self._minute_start_time = time.time()
            self._request_count_minute = 0
            
        # Ensure at least some spacing (e.g. 1s) to be polite?
        # 5 RPM is 1 req every 12s on average.
        # But we might burst 5 then wait 55s. That's allowed.
        
        self._request_count_minute += 1
        self._last_request_time = time.time()

    def _check_budget(self) -> bool:
        """Reads ledger to check daily count."""
        if not self.LEDGER_PATH.exists():
            return True
        
        try:
            with open(self.LEDGER_PATH, "r") as f:
                ledger = json.load(f)
            
            today = datetime.datetime.utcnow().strftime("%Y-%m-%d")
            count = ledger.get(today, {}).get("count", 0)
            
            if count >= self.DAILY_LIMIT:
                return False
            return True
        except:
            return True # Fail open? Or closed? Spec says Fail-Safe (N/A). 
            # If we can't read ledger, maybe safe to assume we can try, or fail close.
            # Let's Fail Open but log error, assuming corrupt ledger shouldn't stop us completely unless full.
            return True

    def _update_ledger(self, symbol: str, function: str):
        """Updates outputs/os/ledger/alpha_vantage_ledger.json"""
        self.LEDGER_PATH.parent.mkdir(parents=True, exist_ok=True)
        
        ledger = {}
        if self.LEDGER_PATH.exists():
            try:
                with open(self.LEDGER_PATH, "r") as f:
                    ledger = json.load(f)
            except:
                ledger = {}
        
        today = datetime.datetime.utcnow().strftime("%Y-%m-%d")
        if today not in ledger:
            ledger[today] = {"count": 0, "logs": []}
            
        ledger[today]["count"] += 1
        # Log detail (optional, keep it lean?)
        log_entry = f"{datetime.datetime.utcnow().isoformat()} - {symbol} - {function}"
        ledger[today]["logs"].append(log_entry)
        
        # Prune logs if too huge? D62 doesn't specify massive pruning, but let's keep it sane.
        if len(ledger[today]["logs"]) > 1000:
             ledger[today]["logs"] = ledger[today]["logs"][-1000:]
             
        # Atomic write
        temp_path = self.LEDGER_PATH.with_suffix(".tmp")
        with open(temp_path, "w") as f:
            json.dump(ledger, f, indent=2)
        os.replace(temp_path, self.LEDGER_PATH)

if __name__ == "__main__":
    # Smoke Test
    client = AlphaVantageClient()
    if client.api_key:
        print("Client initialized with key.")
        # Dry run logic could go here
    else:
        print("Client initialized WITHOUT key (Mock Mode).")
