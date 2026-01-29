
import json
import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional

from backend.artifacts.io import get_artifacts_root, append_to_ledger, safe_read_or_fallback

class ReliabilityReconciler:
    """
    D48.BRAIN.04: Outcome Reconciler.
    Finds open ledger entries, checks 'Realized' price data, and closes the loop.
    Use in Batch Job or on Pulse.
    """
    
    LEDGER_PATH = "ledgers/reliability_ledger_global.jsonl"
    OUTCOMES_PATH = "ledgers/reliability_outcomes.jsonl"
    
    @staticmethod
    def reconcile(symbol: str = "SPY", lookback_hours: int = 48) -> int:
        """
        Scans ledger for entries in the last N hours that are NOT reconciled.
        Attempts to fetch realized outcome.
        Returns count of newly reconciled entries.
        """
        reconciled_count = 0
        
        # 1. Load Existing Outcomes (to skip)
        existing_ids = set()
        outcomes_file = get_artifacts_root() / ReliabilityReconciler.OUTCOMES_PATH
        if outcomes_file.exists():
             with open(outcomes_file, "r") as f:
                 for line in f:
                     try:
                         rec = json.loads(line)
                         existing_ids.add(rec.get("run_id"))
                     except: pass
                     
        # 2. Scan Ledger
        ledger_file = get_artifacts_root() / ReliabilityReconciler.LEDGER_PATH
        if not ledger_file.exists():
            return 0
            
        entries_to_process = []
        now = datetime.datetime.utcnow()
        
        with open(ledger_file, "r") as f:
            for line in f:
                try:
                    entry = json.loads(line)
                    if entry.get("symbol") != symbol: continue
                    if entry.get("run_id") in existing_ids: continue
                    
                    # Time check
                    ts_str = entry.get("timestamp_utc", "")
                    if not ts_str: continue
                    try:
                        ts = datetime.datetime.fromisoformat(ts_str.replace("Z", ""))
                        age_hours = (now - ts).total_seconds() / 3600
                        
                        # Only reconcile if enough time passed?
                        # Actually, if we have the CLOSE data, we can reconcile even if it's fresh.
                        # For V1 Simulation, we assume we check against "Now Price".
                        if age_hours > lookback_hours: continue # Too old, ignore or mark expired? 
                        
                        entries_to_process.append(entry)
                    except: continue
                except: continue
        
        # 3. Process Capabilities
        # Need "Realized Price". In V1 Backend, we don't have a generic "History DB".
        # We rely on IntradaySeriesSource or Polygon fetch.
        # For this D48 Step, we will implement a "Mock/Verification" path 
        # that checks if 'intraday_series.json' has a candle for the day.
        
        for entry in entries_to_process:
            outcome = ReliabilityReconciler._fetch_outcome(entry)
            if outcome:
                append_to_ledger(ReliabilityReconciler.OUTCOMES_PATH, outcome)
                reconciled_count += 1
                
        return reconciled_count

    @staticmethod
    def _fetch_outcome(entry: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Determines realized outcome.
        Strategy: Use Intraday Series to find the Close of the day.
        """
        symbol = entry.get("symbol")
        timeframe = entry.get("timeframe")
        ts_str = entry.get("timestamp_utc", "")
        
        # Simplification for V1:
        # Load the *Current* Intraday Series.
        # Does it contain a completed day matching the Entry's day?
        
        from backend.os_intel.intraday_series_source import IntradaySeriesSource
        
        # We use a helper that doesn't trigger new pipeline logic, just reads.
        # But IntradaySeriesSource.load defaults to Mock if missing.
        # We will assume if we are running the reconciler, we have access to "Truth".
        
        # For Verification Script: We will inject a 'mock_truth' if available?
        # Or standard series.
        
        try:
            # Check if entry date is "Today". 
            entry_dt = datetime.datetime.fromisoformat(ts_str.replace("Z", ""))
            
            # For V1: We will only reconcile if we can find a mock or real close.
            # IN REALITY: We would query Polygon API for "Close on YYYY-MM-DD".
            # HERE: We will check if `outputs/engine/intraday_series.json` has data.
            
            res = safe_read_or_fallback("engine/intraday_series.json")
            if not res["success"]: return None
            
            data = res["data"]
            if data.get("symbol") != symbol: return None
            
            # Find closest candle or final candle
            # This is "Best Effort" V1 reconciliation
            now_candle = data.get("nowCandle")
            
            if not now_candle: return None
            
            close_price = now_candle.get("c")
            
            # Determine result
            # Did it stay in bounds?
            bounds = entry.get("intraday_bounds", {})
            upper = bounds.get("upper_2std", 999999)
            lower = bounds.get("lower_2std", 0)
            
            is_in_bounds = lower <= close_price <= upper
            
            return {
                "run_id": entry["run_id"],
                "reconciled_at_utc": datetime.datetime.utcnow().isoformat(),
                "realized_close": close_price,
                "outcome_type": "INTRADAY_SNAPSHOT", # or DAILY_CLOSE
                "is_in_bounds": is_in_bounds,
                "delta_from_upper": close_price - upper if close_price > upper else 0,
                "delta_from_lower": lower - close_price if close_price < lower else 0
            }
            
        except Exception as e:
            # print(f"Reconcile error: {e}")
            return None
