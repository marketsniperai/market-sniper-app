import json
import os
import datetime
from pathlib import Path
from backend.lexicon_pro_engine import LexiconProEngine

# Canonical Output Paths
OUTPUT_PATH = Path("outputs/engine/evidence_summary.json")

def generate_evidence_summary():
    """
    D36.4 EVIDENCE ENGINE V1
    Deterministically generates descriptive evidence summary based on historical matching.
    Strict Safety: N < 15 => N_A.
    """
    
    # 1. Determine Fingerprint (Mock/Stub for v1)
    # In real engine, this would read market data.
    fingerprint = {
        "regime": "Neutral",
        "trend": "Flat",
        "vol_regime": "Normal"
    }
    
    # 2. Historical Match (Stub)
    # Simulating a lookup
    sample_size = 0 # Default safe
    
    # Logic: Check if we have data (we don't for v1 stub)
    # So we default to insufficient sample size or N_A
    
    diagnostics = {
        "match_method": "STUB_V1",
        "data_window": "N/A",
        "fallback_reason": "INIT_NO_DATA"
    }

    
    # Lexicon
    narrative = {
        "headline": "Insufficient historical matches found.",
        "bullets": []
    }
    # Refine headline
    lex_res = LexiconProEngine.refine_text(narrative["headline"], [])
    narrative["headline"] = lex_res["text"]
    diagnostics["lexicon"] = lex_res
    
    # 3. Build Payload
    # Default to N_A
    payload = {
        "version": "1.0.0",
        "as_of_utc": datetime.datetime.utcnow().isoformat() + "Z",
        "status": "N_A",
        "coverage": "N_A",
        "fingerprint": fingerprint,
        "sample_size": 0,
        "horizon_days": [1, 5],
        "sample_size": 0,
        "horizon_days": [1, 5],
        "metrics": None, # Null if N_A
        "narrative": narrative,
        "diagnostics": diagnostics
    }
    
    # 4. Write Artifact
    _dump(payload)
    return payload

def _dump(payload):
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
    print(f"[EVIDENCE_ENGINE] Artifact written (Status: {payload['status']})")

if __name__ == "__main__":
    generate_evidence_summary()
