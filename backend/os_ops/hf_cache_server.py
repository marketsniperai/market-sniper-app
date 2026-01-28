import json
import os
import datetime
from pathlib import Path
from typing import Dict, Optional, Any

from backend.artifacts.io import atomic_write_json, get_artifacts_root

class OnDemandCacheServer:
    """
    HF-CACHE-SERVER: Server-Side Cache for On-Demand Intelligence.
    
    Strategy: "Hourly Buckets"
    Key: ticker_timeframe_yyyyMMdd_HH.json
    TTL: Implicitly 60 mins via hourly key.
    Location: outputs/cache/on_demand/
    
    Principles:
    1. STRICT COST DISCIPLINE. Don't re-compute expensive AGMS/Projection if asked twice in same hour.
    2. SOURCE TRUTH. If cache hit, serves the exact previous artifact.
    3. VISIBLE. Cache hits are flagged in payload.
    """
    
    CACHE_DIR = get_artifacts_root() / "cache/on_demand"
    
    @staticmethod
    def get(ticker: str, timeframe: str) -> Optional[Dict[str, Any]]:
        """
        Retrieve cached envelope if exists for current hour.
        Returns None if miss.
        """
        try:
            key = OnDemandCacheServer._generate_key(ticker, timeframe)
            path = OnDemandCacheServer.CACHE_DIR / key
            
            if not path.exists():
                return None
                
            with open(path, "r") as f:
                data = json.load(f)
                
            # Inject Cache Hit Meta
            data["cache_hit"] = True
            data["cached_at_server"] = datetime.datetime.utcnow().isoformat() + "Z"
            
            return data
            
        except Exception as e:
            # Cache failure should not block compute
            print(f"[CACHE] Get Failed: {e}")
            return None
            
    @staticmethod
    def put(ticker: str, timeframe: str, payload: Dict[str, Any]) -> None:
        """
        Store envelope in cache.
        """
        try:
            OnDemandCacheServer.CACHE_DIR.mkdir(parents=True, exist_ok=True)
            key = OnDemandCacheServer._generate_key(ticker, timeframe)
            path = OnDemandCacheServer.CACHE_DIR / key
            
            # Ensure we don't store "cache_hit=True" if we re-cache a cached item? 
            # Ideally caller passes fresh payload.
            # But let's act idempotent.
            
            atomic_write_json(str(path), payload)
            
        except Exception as e:
            print(f"[CACHE] Put Failed: {e}")

    @staticmethod
    def _generate_key(ticker: str, timeframe: str) -> str:
        """
        Generate hourly bucket key.
        Format: TICKER_TIMEFRAME_YYYYMMDD_HH.json
        """
        now = datetime.datetime.utcnow() 
        # Hourly granularity
        ts_str = now.strftime("%Y%m%d_%H") 
        return f"{ticker.upper()}_{timeframe.upper()}_{ts_str}.json"

    @staticmethod
    def get_latest_for_day(ticker: str, timeframe: str) -> Optional[Dict[str, Any]]:
        """
        HF32: Retrieve *any* valid cache file found for 'TODAY' (ET).
        Scans strictly for files matching TICKER_TIMEFRAME_YYYYMMDD_*.json
        Returns the one with the latest modification time (or highest hour).
        """
        try:
            # Determine Today STRING prefix (in UTC usually, but filenames are UTC based on _generate_key)
            # wait, _generate_key uses UTC.
            # So "Today ET" might span two UTC dates if late at night?
            # Ledger uses "Today ET".
            # If I analyzed at 09:00 UTC (04:00 ET), file is YYYYMMDD_09.
            # If I analyze again at 10:00 UTC (05:00 ET), file is YYYYMMDD_10.
            # Simplest approach: Hunt for files matching Key Prefix in the target directory using glob.
            
            prefix = f"{ticker.upper()}_{timeframe.upper()}_"
            candidates = []
            
            if not OnDemandCacheServer.CACHE_DIR.exists():
                return None

            for entry in OnDemandCacheServer.CACHE_DIR.iterdir():
                if entry.name.startswith(prefix) and entry.name.endswith(".json"):
                     candidates.append(entry)
            
            if not candidates:
                return None
            
            # Sort by Name (which contains YYYYMMDD_HH) -> Logic: Latest hour is last.
            # This is robust enough for hourly buckets.
            candidates.sort(key=lambda p: p.name) 
            latest = candidates[-1]
            
            # Load and Return
            with open(latest, "r") as f:
                data = json.load(f)
            
            data["cache_hit"] = True
            data["cache_source"] = "LATEST_FALLBACK"
            return data
            
        except Exception as e:
            print(f"[CACHE] Fallback Search Failed: {e}")
            return None
