import json
import os
import datetime
from pathlib import Path
from backend.options_provider import get_provider
from backend.options_compute import compute_options_context
from backend.lexicon_pro_engine import LexiconProEngine

# Canonical Output Paths
OUTPUT_PATH = Path("outputs/engine/options_context.json")
CACHE_PATH = Path("outputs/cache/options_cache.json")

def generate_options_context():
    """
    v1.1.0 ENGINE ORCHESTRATION
    1. Check Provider Config
    2. Check Cache
    3. Fetch from Provider (if config & no cache hit)
    4. Compute Metrics
    5. Write Artifact
    """
    
    # Setup Diagnostic Tracking
    diagnostics = {
        "provider_attempted": False,
        "provider_result": "NONE",
        "cache_age_seconds": None,
        "fallback_reason": None
    }
    
    provider = get_provider()
    symbol = "SPY"
    
    # ---------------------------------------------------------
    # A. Check Configuration
    # ---------------------------------------------------------
    if not provider.is_configured():
        diagnostics["fallback_reason"] = "PROVIDER_DENIED_NO_KEY"
        _write_artifact(symbol, "PROVIDER_DENIED", "N_A", diagnostics, 
                       "Options Intelligence offline. API Key missing.",
                       iv_regime="N/A", skew="N/A", exp_move="N/A")
        return

    # ---------------------------------------------------------
    # B. Check Cache
    # ---------------------------------------------------------
    cached_data = _read_cache(symbol)
    if cached_data:
        # Robust ISO parsing
        ts_str = cached_data["cached_at_utc"].replace("Z", "")
        # If no decimals, padding might be needed or just try/except
        try:
             cache_dt = datetime.datetime.fromisoformat(ts_str)
             age = (datetime.datetime.utcnow() - cache_dt).total_seconds()
             
             diagnostics["cache_age_seconds"] = int(age)
             
             # Adjust age - manually seeded cache might be "future" or skew context, just ensure positive
             if age < 0: age = 0
             
             if age < 3600: # 1 Hour TTL
                 # Cache Hit
                 payload = cached_data["payload"]
                 _write_artifact_from_payload(payload, "CACHE", diagnostics)
                 return
        except Exception as e:
             # Corrupt timestamp? Ignore.
             diagnostics["cache_age_seconds"] = -1
    
    # ---------------------------------------------------------
    # C. Fetch Provider
    # ---------------------------------------------------------
    diagnostics["provider_attempted"] = True
    try:
        snapshot = provider.fetch_snapshot(symbol)
        diagnostics["provider_result"] = "SUCCESS"
        
        # Compute
        metrics = compute_options_context(snapshot)
        
        # Build Result
        final_payload = {
            "status": "LIVE",
            "coverage": "FULL",
            "symbol": symbol,
            "iv_regime": metrics["iv_regime"],
            "skew": metrics["skew"],
            "expected_move": metrics["expected_move"],
            "expected_move_horizon": metrics["expected_move_horizon"],
            "confidence": "HIGH",
            "data_sources": [{"name": provider.get_name(), "state": "LIVE"}],
            "note": "Live data from provider.",
             # Will add diagnostics, as_of, etc in writer
        }
        
        # Update Cache
        _write_cache(symbol, final_payload)
        
        # Write Artifact
        _write_artifact_from_payload(final_payload, "LIVE", diagnostics)

    except Exception as e:
        diagnostics["provider_result"] = "ERROR"
        diagnostics["fallback_reason"] = str(e)
        
        # Fallback to Cache if available (even if stale, maybe? for now strict N_A per task)
        # Task says: "If timeout/network => ERROR (but still produce artifact with status ERROR...)"
        
        _write_artifact(symbol, "ERROR", "N_A", diagnostics, 
                       f"Provider fetch failed: {str(e)}",
                       iv_regime="N/A", skew="N/A", exp_move="N/A")


def _read_cache(symbol: str):
    if not CACHE_PATH.exists(): return None
    try:
        data = json.loads(CACHE_PATH.read_text(encoding='utf-8'))
        if data.get("symbol") == symbol:
            return data
    except:
        return None
    return None

def _write_cache(symbol: str, payload: dict):
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    cache_entry = {
        "symbol": symbol,
        "cached_at_utc": datetime.datetime.utcnow().isoformat() + "Z",
        "payload": payload
    }
    with open(CACHE_PATH, "w") as f:
        json.dump(cache_entry, f, indent=2)

def _write_artifact_from_payload(payload_in: dict, status_override: str, diagnostics: dict):
    # Enforce contract fields over payload
    payload = payload_in.copy()
    payload["status"] = status_override
    payload["as_of_utc"] = datetime.datetime.utcnow().isoformat() + "Z"
    payload["diagnostics"] = diagnostics
    payload["version"] = "1.1.0"
    
    # Lexicon Refine Note
    if "note" in payload:
         lex_res = LexiconProEngine.refine_text(payload["note"], ["Options Intel"])
         payload["note"] = lex_res["text"]
         payload["diagnostics"]["lexicon"] = lex_res

    _dump(payload)

def _write_artifact(symbol, status, coverage, diagnostics, note, iv_regime="N_A", skew="N/A", exp_move="N/A"):
    payload = {
        "version": "1.1.0",
        "as_of_utc": datetime.datetime.utcnow().isoformat() + "Z",
        "symbol": symbol,
        "status": status,
        "coverage": coverage,
        "iv_regime": iv_regime,
        "skew": skew,
        "expected_move": exp_move,
        "expected_move_horizon": "1D" if exp_move != "N/A" else "N/A",
        "confidence": "N_A",
        "data_sources": [],
        "diagnostics": diagnostics,
        "note": note
    }
    _dump(payload)

def _dump(payload):
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
    print(f"[OPTIONS_ENGINE_V1.1] Artifact written (Status: {payload['status']})")


if __name__ == "__main__":
    generate_options_context()
