import json
import os
import datetime
from pathlib import Path
from backend.lexicon_pro_engine import LexiconProEngine

# Canonical Output Paths
OUTPUT_PATH = Path("outputs/engine/macro_context.json")
CACHE_PATH = Path("outputs/cache/macro_cache.json")

def generate_macro_context():
    """
    D36.5 MACRO ENGINE V1
    Deterministically generates descriptive macro context (Rates, Dollar, Oil).
    Falls back to N/A if no data sources available.
    """
    
    # Diagnostics
    diagnostics = {
        "sources_used": [],
        "fallback_reason": None,
        "cache_age_seconds": None
    }
    
    # 1. Check Cache
    cached_data = _read_cache()
    if cached_data:
        try:
             ts_str = cached_data["cached_at_utc"].replace("Z", "")
             cache_dt = datetime.datetime.fromisoformat(ts_str)
             age = (datetime.datetime.utcnow() - cache_dt).total_seconds()
             diagnostics["cache_age_seconds"] = int(age)
             
             if age < 43200: # 12 Hour TTL for Macro
                 _write_artifact_from_payload(cached_data["payload"], "CACHE", diagnostics)
                 return
        except:
             pass

    # 2. Live Fetch (Stub for now)
    # If keys existed, we'd check them here.
    
    # 3. Default / Fallback
    diagnostics["fallback_reason"] = "NO_PROVIDERS_CONFIGURED"
    
    raw_summary = "Macro context offline. No providers."
    lex_res = LexiconProEngine.refine_text(raw_summary, [])
    diagnostics["lexicon"] = lex_res
    
    _write_artifact("N_A", "N_A", diagnostics, 
                   lex_res["text"],
                   rates="N/A", dollar="N/A", oil="N/A")

def _read_cache():
    if not CACHE_PATH.exists(): return None
    try:
        return json.loads(CACHE_PATH.read_text(encoding='utf-8'))
    except:
        return None

def _write_artifact_from_payload(payload_in: dict, status_override: str, diagnostics: dict):
    payload = payload_in.copy()
    payload["status"] = status_override
    payload["as_of_utc"] = datetime.datetime.utcnow().isoformat() + "Z"
    payload["diagnostics"] = diagnostics
    payload["version"] = "1.0.0"
    _dump(payload)

def _write_artifact(status, coverage, diagnostics, summary, rates="N/A", dollar="N/A", oil="N/A"):
    payload = {
        "version": "1.0.0",
        "as_of_utc": datetime.datetime.utcnow().isoformat() + "Z",
        "status": status,
        "coverage": coverage,
        "rates_context": rates,
        "dollar_context": dollar,
        "oil_context": oil,
        "summary": summary,
        "diagnostics": diagnostics
    }
    _dump(payload)

def _dump(payload):
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
    print(f"[MACRO_ENGINE] Artifact written (Status: {payload['status']})")

if __name__ == "__main__":
    generate_macro_context()
