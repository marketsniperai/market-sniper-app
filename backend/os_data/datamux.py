
from typing import Dict, Any, List, Optional
import json
import datetime
from pathlib import Path
from backend.artifacts.io import get_artifacts_root, safe_read_or_fallback, atomic_write_json

# --- DataResult Contract ---

class DataResult:
    """
    Standardized response from DataMux.
    """
    def __init__(self, 
                 status: str, 
                 provider: str, 
                 payload: Any, 
                 error_code: Optional[str] = None):
        self.status = status # LIVE, DENIED, OFFLINE, DEMO
        self.provider = provider
        self.payload = payload
        self.error_code = error_code
        self.as_of_utc = datetime.datetime.utcnow().isoformat()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "status": self.status,
            "provider": self.provider,
            "error_code": self.error_code,
            "as_of_utc": self.as_of_utc,
            "payload": self.payload
        }

# --- DataMux ---

class DataMux:
    """
    D48.BRAIN.05: Provider Data Multiplexer.
    Routes requests to providers based on Priority Config.
    """
    
    CONFIG_PATH = "config/provider_config.json"
    HEALTH_ARTIFACT_PATH = "os/engine/provider_health.json"
    
    @staticmethod
    def _load_config() -> Dict[str, Any]:
        root = get_artifacts_root()
        path = Path(__file__).parent / "provider_config.json" # Use local default or artifact?
        # User said backend/os_data/provider_config.json
        if path.exists():
            with open(path, "r") as f:
                return json.load(f)
        return {
            "candles": ["yahoo_stub", "demo"],
            "options": ["demo"],
            "news": ["demo"],
            "macro": ["demo"]
        }

    @staticmethod
    def _record_health(provider: str, success: bool, error_code: str = None):
        """Append-only health track? Or overwrite status?"""
        # Using overwrite for status artifact as per spec
        # "Produces provider health artifact"
        try:
            root = get_artifacts_root()
            path = root / "os/engine/provider_health.json"
            
            data = {}
            if path.exists():
                try: 
                    with open(path, "r") as f: data = json.load(f)
                except: pass
                
            entry = data.get(provider, {"last_success_utc": None, "failures": 0, "denied": False})
            
            if success:
                entry["last_success_utc"] = datetime.datetime.utcnow().isoformat()
                entry["failures"] = 0 # Reset failures on success? Or keep total?
            else:
                entry["failures"] = entry.get("failures", 0) + 1
                entry["last_error_code"] = error_code
                if error_code == "DENIED":
                    entry["denied"] = True
                    
            data[provider] = entry
            
            path.parent.mkdir(parents=True, exist_ok=True)
            atomic_write_json(str(path), data)
            
        except Exception as e:
            print(f"[DataMux] Health Write Failed: {e}")

    @staticmethod
    def fetch_candles(symbol: str, timeframe: str, granularity: str = "daily") -> Dict[str, Any]:
        """
        Fetches candle data.
        """
        cfg = DataMux._load_config()
        providers = cfg.get("candles", ["demo"])
        
        for p in providers:
            # Stub logic for now
            if p == "yahoo_stub":
                # Simulate failover for test or stub success
                if symbol == "FAIL":
                    DataMux._record_health(p, False, "CONNECTION_ERROR")
                    continue
                if symbol == "DENY":
                    DataMux._record_health(p, False, "DENIED")
                    continue
                    
                DataMux._record_health(p, True)
                return DataResult("LIVE", p, {"candles": [], "symbol": symbol}).to_dict()
                
            elif p == "demo":
                DataMux._record_health(p, True)
                return DataResult("DEMO", p, {"candles": "DEMO_DATA", "symbol": symbol}).to_dict()
                
        return DataResult("OFFLINE", "NONE", None, "ALL_PROVIDERS_FAILED").to_dict()

    @staticmethod
    def fetch_news(symbol: str) -> Dict[str, Any]:
        return DataResult("DEMO", "demo", {"news": []}).to_dict()
        
    @staticmethod
    def fetch_options(symbol: str) -> Dict[str, Any]:
        return DataResult("DEMO", "demo", {"chain": {}}).to_dict()
        
    @staticmethod
    def fetch_macro() -> Dict[str, Any]:
        return DataResult("DEMO", "demo", {"rates": {}}).to_dict()
