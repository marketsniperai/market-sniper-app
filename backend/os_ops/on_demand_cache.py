import os
import json
import hashlib
from typing import Optional, List, Dict
from datetime import datetime, timedelta
from pydantic import BaseModel
from backend.artifacts.io import safe_read_or_fallback

# --- MODELS ---
class OnDemandCacheKey(BaseModel):
    ticker: str
    request_type: str = "CONTEXT_SNAPSHOT"

class OnDemandCacheEntry(BaseModel):
    key: OnDemandCacheKey
    created_utc: str
    expires_utc: str
    tier: str
    payload: Dict
    payload_hash: str
    bytes: int

class OnDemandCacheGetResult(BaseModel):
    status: str
    cache_hit: bool
    freshness: str # LIVE | STALE | UNAVAILABLE
    entry: Optional[OnDemandCacheEntry] = None
    reason: Optional[str] = None

# --- CONSTANTS ---
CACHE_DIR = "outputs/on_demand_cache"
INDEX_FILE = f"{CACHE_DIR}/index.json"
POLICY_FILE = "outputs/os/os_on_demand_cache_policy.json"

# --- ENGINE ---
class OnDemandCache:
    
    @staticmethod
    def _read_policy():
        res = safe_read_or_fallback(POLICY_FILE)
        if res["success"]:
            return res["data"]
        # Fallback defaults if policy missing (should not happen in sealed system)
        return {
             "ttl_seconds": {"free": 900, "plus": 1800, "elite": 3600},
             "bounds": {"max_entries": 50, "max_bytes_total": 512000}
        }

    @staticmethod
    def _ensure_dir():
        os.makedirs(CACHE_DIR, exist_ok=True)

    @staticmethod
    def _get_index() -> List[Dict]:
        if not os.path.exists(INDEX_FILE):
             return []
        try:
             with open(INDEX_FILE, 'r') as f:
                 return json.load(f)
        except: return []
    
    @staticmethod
    def _save_index(index: List[Dict]):
        try:
             with open(INDEX_FILE, 'w') as f:
                 json.dump(index, f, indent=2)
        except: pass

    @staticmethod
    def _evict_needed(index: List[Dict], current_bytes: int, policy: Dict) -> List[Dict]:
        max_entries = policy["bounds"]["max_entries"]
        max_bytes = policy["bounds"]["max_bytes_total"]
        
        # Evict while over bounds
        # Sort by created_utc (oldest first) - assuming index is append-only implies order, 
        # but to be safe we can sort valid entries.
        # Minimal impl: FIFO (index[0] is oldest)
        
        while len(index) > 0 and (len(index) > max_entries or current_bytes > max_bytes):
            removed = index.pop(0)
            # Delete file
            path = f"{CACHE_DIR}/{removed['filename']}"
            if os.path.exists(path):
                try: 
                    current_bytes -= os.path.getsize(path)
                    os.remove(path)
                except: pass
        
        return index

    @staticmethod
    def get(ticker: str, tier: str = "FREE", allow_stale: bool = False) -> OnDemandCacheGetResult:
        OnDemandCache._ensure_dir()
        index = OnDemandCache._get_index()
        req_type = "CONTEXT_SNAPSHOT"
        
        # Find in index
        # key: ticker is distinct
        found_meta = None
        for item in index:
            if item["key"]["ticker"] == ticker and item["key"]["request_type"] == req_type:
                found_meta = item
                break
        
        if not found_meta:
            return OnDemandCacheGetResult(status="MISS", cache_hit=False, freshness="UNAVAILABLE")
            
        # Check Expiry
        expires = datetime.fromisoformat(found_meta["expires_utc"])
        now = datetime.now() # naive/local or utc? Policy uses ISO strings. 
        # Ideally we use UTC everywhere.
        # Let's assume isoformat is capable of comparison if both aware or naive.
        # The writer writes isoformat().
        
        # Simple string compare works for ISO8601 if same timezone.
        # Let's parse.
        
        is_expired = now > expires
        
        if is_expired and not allow_stale:
            return OnDemandCacheGetResult(status="EXPIRED", cache_hit=False, freshness="STALE", reason="TTL Exceeded")
            
        # Load Payload
        path = f"{CACHE_DIR}/{found_meta['filename']}"
        if not os.path.exists(path):
             return OnDemandCacheGetResult(status="CORRUPT", cache_hit=False, freshness="UNAVAILABLE", reason="File Missing")
             
        try:
            with open(path, 'r') as f:
                data = json.load(f)
                entry = OnDemandCacheEntry(**data)
                
                freshness = "LIVE"
                if is_expired: freshness = "STALE"
                
                return OnDemandCacheGetResult(status="HIT", cache_hit=True, freshness=freshness, entry=entry)
        except Exception as e:
            return OnDemandCacheGetResult(status="ERROR", cache_hit=False, freshness="UNAVAILABLE", reason=str(e))

            return OnDemandCacheGetResult(status="ERROR", cache_hit=False, freshness="UNAVAILABLE", reason=str(e))

    @staticmethod
    def _try_load_pipeline_envelope(ticker: str) -> 'Tuple[Optional[Dict], str]':
        """
        D47.HF15: Pipeline Artifact Reader.
        Path: outputs/on_demand_pipeline/{ticker}.json
        Returns: (envelope_dict or None, status_note)
        Notes: OK | MISSING | CORRUPT | SCHEMA_FAIL
        """
        # Canonical Path
        # We assume ticker is safe (Enforcer checks it), but good to be safe again for filesystem.
        safe_ticker = ticker.replace("..", "").replace("/", "").replace("\\", "").upper()
        path = f"outputs/on_demand_pipeline/{safe_ticker}.json"
        
        if not os.path.exists(path):
            return (None, "MISSING")
            
        try:
            with open(path, 'r') as f:
                data = json.load(f)
                
            # Quick Schema Validation
            # Minimal requirements for a valid PIPELINE source envelope
            if not isinstance(data, dict):
                return (None, "SCHEMA_FAIL")
                
            # Must minimally allow EnvelopeBuilder to work or be pre-built.
            # We look for critical fields.
            # If it's a raw artifact, EnvelopeBuilder might need to adapt it. 
            # But the contract said "Artifact must contain a StandardEnvelope-compatible payload".
            
            # Check 1: Ticker match (Safety)
            # If data has "ticker", it should match. If missing, maybe okay if filename matches.
            # Let's enforce it if present.
            if "ticker" in data and data["ticker"] != safe_ticker:
                 return (None, "SCHEMA_FAIL_TICKER_MISMATCH")
                 
            # Check 2: Payload or Bullets
            # If it's a StandardEnvelope, it has 'bullets'. If raw, maybe different.
            # We assume it follows StandardEnvelope shape or roughly close.
            # Let's just check it's not empty.
            if not data:
                return (None, "CORRUPT_EMPTY")
                
            return (data, "OK")
            
        except json.JSONDecodeError:
            return (None, "CORRUPT_JSON")
        except Exception:
            return (None, "CORRUPT_READ")

    @staticmethod
    def resolve_source(ticker: str, tier: str = "FREE", allow_stale: bool = False) -> Dict:
        """
        D44.X Source Ladder:
        1. PIPELINE_ARTIFACT (Not yet implemented, stub)
        2. ON_DEMAND_CACHE
        3. OFFLINE_FALLBACK
        """
        
        """
        
        # 1. Pipeline Artifact (D47.HF15 Hook)
        pipe_env, pipe_note = OnDemandCache._try_load_pipeline_envelope(ticker)
        if pipe_env and pipe_note == "OK":
             return {
                 "source": "PIPELINE",
                 "freshness": "LIVE", # Pipeline artifacts are source truth
                 "status": "AVAILABLE",
                 "payload": pipe_env,
                 "timestamp_utc": pipe_env.get("timestamp_utc", datetime.now(timezone.utc).isoformat()),
                 "_pipeline_note": pipe_note # Internal debug
             }
        
        # 2. Cache
        cache_res = OnDemandCache.get(ticker, tier, allow_stale)
        if cache_res.status == "HIT":
             return {
                 "source": "CACHE",
                 "freshness": cache_res.freshness,
                 "status": "AVAILABLE",
                 "payload": cache_res.entry.payload,
                 "timestamp_utc": cache_res.entry.created_utc,
                 "_pipeline_note": pipe_note # Carry forward miss reason
             }
             
        # 3. Offline / Live Provider (Not integrated)
        # If cache missed/expired, we default to OFFLINE for now as we don't have live providers.
        # But we must return a valid envelope so UI shows "Offline" badge.
        
        return {
            "source": "OFFLINE",
            "freshness": "UNAVAILABLE", 
            "status": "OFFLINE",
            "payload": {
                "ticker": ticker,
                "global_risk": "UNKNOWN", 
                "regime": "UNKNOWN",
                "note": "Market data providers are not connected."
            },
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "_pipeline_note": pipe_note # Carry forward miss reason
        }

    @staticmethod
    def put(ticker: str, payload: Dict, tier: str = "FREE"):
        OnDemandCache._ensure_dir()
        policy = OnDemandCache._read_policy()
        
        ttl = policy["ttl_seconds"].get(tier.lower(), 900)
        now = datetime.now()
        expires = now + timedelta(seconds=ttl)
        
        req_type = "CONTEXT_SNAPSHOT"
        key = OnDemandCacheKey(ticker=ticker, request_type=req_type)
        
        payload_str = json.dumps(payload)
        payload_hash = hashlib.md5(payload_str.encode()).hexdigest()
        size_bytes = len(payload_str)
        
        entry = OnDemandCacheEntry(
            key=key,
            created_utc=now.isoformat(),
            expires_utc=expires.isoformat(),
            tier=tier,
            payload=payload,
            payload_hash=payload_hash,
            bytes=size_bytes
        )
        
        filename = f"{ticker}__{req_type}.json"
        
        # Update Index
        index = OnDemandCache._get_index()
        # Remove existing if any
        index = [i for i in index if not (i["key"]["ticker"] == ticker and i["key"]["request_type"] == req_type)]
        
        # Calculate current total bytes (approx)
        total_bytes = sum(i.get("bytes", 0) for i in index)
        
        # Add new
        meta = {
            "key": key.dict(),
            "filename": filename,
            "expires_utc": expires.isoformat(),
            "created_utc": now.isoformat(),
            "bytes": size_bytes
        }
        index.append(meta)
        
        # Evict
        index = OnDemandCache._evict_needed(index, total_bytes + size_bytes, policy)
        
        # Write File
        with open(f"{CACHE_DIR}/{filename}", 'w') as f:
            f.write(entry.json())
            
        # Write Index
        OnDemandCache._save_index(index)

        
