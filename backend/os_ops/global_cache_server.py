import json
import os
import datetime
from pathlib import Path
from typing import Dict, Optional, Any

from backend.artifacts.io import atomic_write_json, get_artifacts_root

class GlobalCacheServer:
    """
    HF-DEDUPE-GLOBAL: Server-Side Global Cache (Public/Shared).
    
    Authority: HF-DEDUPE-GLOBAL-REUSE
    
    Strategy: "Global Hourly Buckets"
    Key: ticker/timeframe/YYYYMMDD_HH.json
    Location: outputs/on_demand_public/
    
    Principles:
    1. READ-MANY: One compute serves infinite users.
    2. NO PII: Public bucket contains ONLY instrument data.
    3. SOURCE ATTRIBUTION: Must flag `source=GLOBAL_CACHE`.
    """
    
    # Maps to GCSFuse mount for gs://.../on_demand_public/
    GLOBAL_CACHE_DIR = get_artifacts_root() / "on_demand_public"
    
    @staticmethod
    def get(ticker: str, timeframe: str) -> Optional[Dict[str, Any]]:
        """
        Retrieve globally cached envelope.
        Returns None if miss.
        """
        try:
            key = GlobalCacheServer._generate_key(ticker, timeframe)
            path = GlobalCacheServer.GLOBAL_CACHE_DIR / key
            
            if not path.exists():
                return None
                
            with open(path, "r") as f:
                data = json.load(f)
            
            # Metadata Check (Safety)
            if not data.get("public"):
                 # If it doesn't say public, treat as unsafe/private and ignore
                 return None

            # Inject Source Attribution (Override previous if needed)
            data["source"] = "GLOBAL_CACHE"
            data["cache_hit"] = True 
            # Note: We keep original `cached_at_server` or `asOfUtc` 
            # so user sees true age.
            
            return data
            
        except Exception as e:
            print(f"[GLOBAL_CACHE] Get Failed: {e}")
            return None
            
    @staticmethod
    def put(ticker: str, timeframe: str, payload: Dict[str, Any]) -> None:
        """
        Store envelope in global cache.
        MUST be PII free. Caller responsibility, but we enforce metadata.
        """
        try:
            # Safety: Enforce Public Flag
            payload["public"] = True
            
            # Ensure Directory Structure: ticker/timeframe/
            key = GlobalCacheServer._generate_key(ticker, timeframe)
            path = GlobalCacheServer.GLOBAL_CACHE_DIR / key
            
            path.parent.mkdir(parents=True, exist_ok=True)
            
            atomic_write_json(str(path), payload)
            
        except Exception as e:
            print(f"[GLOBAL_CACHE] Put Failed: {e}")

    @staticmethod
    def _generate_key(ticker: str, timeframe: str) -> str:
        """
        Generate global hourly bucket key.
        Format: TICKER/TIMEFRAME/YYYYMMDD_HH.json
        """
        now = datetime.datetime.utcnow() 
        ts_str = now.strftime("%Y%m%d_%H")
        
        # Nested structure for better GCS performance/browsability
        return f"{ticker.upper()}/{timeframe.upper()}/{ts_str}.json"

    @staticmethod
    def get_latest_for_day(ticker: str, timeframe: str) -> Optional[Dict[str, Any]]:
        """
        HF32: Retrieve *any* valid cache file found for 'TODAY' (ET) in Global Cache.
        """
        try:
            # Construct glob pattern for finding today's files in the hierarchy.
            # outputs/on_demand_public/{TICKER}/{TIMEFRAME}/{YYYYMMDD_HH}.json
            # We need to find valid HH files.
            
            # Since Global cache uses nested folders, we just scan that folder.
            cache_folder = GlobalCacheServer.GLOBAL_CACHE_DIR / ticker.upper() / timeframe.upper()
            
            if not cache_folder.exists():
                return None
                
            candidates = []
            for entry in cache_folder.iterdir():
                 if entry.name.endswith(".json"):
                     candidates.append(entry)
                     
            if not candidates:
                 return None
                 
            # Sort by name (YYYYMMDD_HH) -> Latest is last
            candidates.sort(key=lambda p: p.name)
            latest = candidates[-1]
            
            with open(latest, "r") as f:
                data = json.load(f)
            
            if not data.get("public"):
                 return None
                 
            data["cache_hit"] = True
            data["cache_source"] = "GLOBAL_LATEST_FALLBACK"
            return data
            
        except Exception as e:
             print(f"[GLOBAL_CACHE] Fallback Search Failed: {e}")
             return None
