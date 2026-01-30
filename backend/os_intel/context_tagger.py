
from typing import Dict, Any, List, Optional
import datetime

class ContextTagger:
    """
    D47.HF20: Signals-Free Context Fusion.
    Derives deterministic tags from raw intelligence inputs.
    """
    
    @staticmethod
    def tag_options(options_data: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Derives Options Context Tags & Boundary Mode.
        """
        tags = []
        boundary_mode = "NONE" # NONE | IV_SCALE | EXPECTED_MOVE
        state = "N_A"
        
        if not options_data or options_data.get("status") in ["N_A", "ERROR", "STUB", "PROVIDER_DENIED"]:
            tags.append("OPTIONS_N_A")
            return {"state": state, "tags": tags, "boundary_mode": "NONE"}
            
        state = "LIVE"
        
        # 1. Expected Move Check
        # If we have explicit expected moves (cone), that's superior.
        if options_data.get("expected_move") and options_data["expected_move"] != "N/A":
             boundary_mode = "EXPECTED_MOVE"
             tags.append("OPTIONS_EXPECTED_MOVE_ACTIVE")
        
        # 2. IV Regime Check (Fallback or Augment)
        iv_rank = options_data.get("implied_volatility_rank", "NORMAL")
        if iv_rank == "HIGH":
            tags.append("IV_REGIME_HIGH")
            if boundary_mode == "NONE": boundary_mode = "IV_SCALE"
        elif iv_rank == "LOW":
            tags.append("IV_REGIME_LOW")
            if boundary_mode == "NONE": boundary_mode = "IV_SCALE"
        else:
            tags.append("IV_REGIME_NORMAL")
            
        return {
            "state": state,
            "tags": tags,
            "boundary_mode": boundary_mode
        }

    @staticmethod
    def tag_news(news_data: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Derives News Context Tags.
        """
        tags = []
        state = "N_A"
        dominant_bucket = "NONE"
        dominant_recency = "NONE"

        if not news_data or news_data.get("status") not in ["EXISTING", "LIVE"]:
            return {"state": state, "tags": tags, "dominant_bucket": dominant_bucket, "dominant_recency": dominant_recency}
            
        state = "LIVE"
        items = news_data.get("items", [])
        
        if not items:
            tags.append("NEWS_EMPTY")
            return {"state": state, "tags": tags, "dominant_bucket": "NONE", "dominant_recency": "NONE"}

        # Logic: Determine dominance
        # Simple heuristic for now: Take top item properties or aggregate
        # For V0, let's look at the first item (Rank 1)
        top_item = items[0]
        
        # Bucket
        # Assuming item has 'bucket' or derived from keywords. 
        # If stub structure doesn't have buckets, we guess.
        # Stub from HF19 didn't show structure, let's assume standard 'bucket' key or default.
        dominant_bucket = top_item.get("bucket", "general").lower()
        
        # Recency
        # Parse 'published_utc' or similar
        # For now, simplistic check
        dominant_recency = "today" 
        
        # Tag Generation
        if dominant_bucket == "macro":
            tags.append("MACRO_HEADLINES")
        elif dominant_bucket == "watchlist":
            tags.append("WATCHLIST_RELEVANT")
            
        # Keywords
        snippet = (top_item.get("headline", "") + " " + top_item.get("summary", "")).lower()
        if "earning" in snippet or "guidance" in snippet:
            tags.append("EARNINGS_CLUSTER")
        if any(x in snippet for x in ["fed", "fomc", "powell", "rate"]):
            tags.append("CENTRAL_BANK_FOCUS")
        if any(x in snippet for x in ["cpi", "pce", "inflation"]):
            tags.append("INFLATION_DATA")
        if any(x in snippet for x in ["war", "conflict", "sanction"]):
            tags.append("GEO_RISK")

        return {
            "state": state,
            "tags": tags,
            "dominant_bucket": dominant_bucket,
            "dominant_recency": dominant_recency
        }

    @staticmethod
    def tag_macro(macro_data: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        tags = []
        state = "N_A"
        risk_context = "UNKNOWN"
        
        if not macro_data:
            return {"state": state, "tags": tags, "risk_context": risk_context}

        # Check for stub
        if macro_data.get("status") == "AVAILABLE": # Simple stub check
             state = "STUB_NEUTRAL"
             tags.append("MACRO_STUB_NEUTRAL")
             risk_context = "NEUTRAL"
        else:
             state = "LIVE"
             # Real logic here if data existed
             pass
             
        return {
            "state": state,
            "tags": tags,
            "risk_context": risk_context
        }
