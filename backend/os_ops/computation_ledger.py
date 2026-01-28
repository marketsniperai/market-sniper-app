import json
import datetime
from pathlib import Path
from typing import Dict, Any, Optional

from backend.artifacts.io import atomic_write_json, get_artifacts_root

class ComputationLedger:
    """
    HF32: COMPUTATION LEDGER
    Tracks 'Last Compute Time' per Ticker/Timeframe to enforce daily limits.
    
    Persistence: outputs/os/ledger/computation_ledger.json
    Key: "TICKER_TIMEFRAME"
    Value: "YYYY-MM-DDTHH:MM:SS.mmmmmm" (UTC)
    """
    
    LEDGER_PATH = get_artifacts_root() / "os/ledger/computation_ledger.json"
    
    @staticmethod
    def _load() -> Dict[str, str]:
        if not ComputationLedger.LEDGER_PATH.exists():
            return {}
        try:
            with open(ComputationLedger.LEDGER_PATH, "r") as f:
                return json.load(f)
        except:
            return {}

    @staticmethod
    def _save(data: Dict[str, str]):
        ComputationLedger.LEDGER_PATH.parent.mkdir(parents=True, exist_ok=True)
        atomic_write_json(str(ComputationLedger.LEDGER_PATH), data)

    @staticmethod
    def record(ticker: str, timeframe: str):
        """Record a computation occurring NOW (UTC)."""
        data = ComputationLedger._load()
        key = f"{ticker.upper()}_{timeframe.upper()}"
        data[key] = datetime.datetime.utcnow().isoformat()
        ComputationLedger._save(data)

    @staticmethod
    def has_run_today(ticker: str, timeframe: str) -> bool:
        """
        Check if computation ran 'TODAY' in US/Eastern time.
        Day boundary: 00:00 ET.
        """
        data = ComputationLedger._load()
        key = f"{ticker.upper()}_{timeframe.upper()}"
        last_iso = data.get(key)
        
        if not last_iso:
            return False
            
        try:
            last_utc = datetime.datetime.fromisoformat(last_iso)
            now_utc = datetime.datetime.utcnow()
            
            # Convert both to ET (UTC-5 for simplicity/robustness without heavy tz dep)
            # D47.HFxx: Standardized Manual Offset for ET (No pytz dependency)
            offset = datetime.timedelta(hours=5) 
            last_et = last_utc - offset
            now_et = now_utc - offset
            
            return last_et.date() == now_et.date()
            
        except Exception as e:
            print(f"[LEDGER] Date Parse Error: {e}")
            return False
