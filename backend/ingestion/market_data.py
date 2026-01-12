import os
import random
from typing import Dict, Any, Tuple

# Simple deterministic logic for Day 04
# No real API calls yet, but structure is ready for injection

def fetch_market_snapshot() -> Tuple[Dict[str, Any], str]:
    """
    Returns (snapshot_dict, status_string)
    Status: "OK", "STUB", "ERROR"
    """
    
    # Check for keys (Day 04: Assume missing -> STUB)
    api_key = os.environ.get("FMP_KEY")
    
    if not api_key:
        return _generate_stub_snapshot(), "STUB"
        
    try:
        # Placeholder for real fetch
        # For Day 04, even if key exists, we might default to stub if not implemented
        return _generate_stub_snapshot(), "STUB" 
    except Exception:
        return {}, "ERROR"

def _generate_stub_snapshot() -> Dict[str, Any]:
    """
    Deterministic stub.
    """
    return {
        "spy_price": 450.00,
        "spy_change_pct": 0.05,
        "vix_level": 15.5,
        "regime": "NEUTRAL",
        "is_stub": True
    }
