import json
from pathlib import Path
import datetime
from typing import Dict, Any, List, Optional

from backend.artifacts.io import safe_read_or_fallback, atomic_write_json, get_artifacts_root

class NewsEngine:
    """
    D47.HF-A: News Backend Unification.
    Provides deterministic DEMO news truth if pipeline artifact is missing.
    Ensures Source Ladder: PIPELINE -> DEMO -> 200 OK.
    """
    
    ARTIFACT_SUBDIR = "engine"
    ARTIFACT_FILENAME = "news_digest.json"
    
    @staticmethod
    def get_artifact_path() -> Path:
        return get_artifacts_root() / NewsEngine.ARTIFACT_SUBDIR / NewsEngine.ARTIFACT_FILENAME

    @staticmethod
    def generate_demo_news_digest() -> Dict[str, Any]:
        """
        Generates a deterministic DEMO news set based on today's date.
        Writes it to disk so it becomes the truth artifact.
        """
        now = datetime.datetime.utcnow()
        date_str = now.strftime("%Y-%m-%d")
        
        # Deterministic items based on date to avoid reload flicker
        # We assume standard categories needed for ContextTagger: 
        # headline, bucket, summary, published_utc
        
        items = [
            {
                "id": f"demo-{date_str}-1",
                "headline": "Fed Signals Steady Approach Amidst Inflation Data",
                "summary": "Federal Reserve officials indicate patience as recent CPI prints show mixed signals. Markets await further guidance.",
                "bucket": "macro", 
                "source": "MarketSniper Wire (Demo)",
                "published_utc": now.isoformat() + "Z",
                "url": "#"
            },
            {
                "id": f"demo-{date_str}-2",
                "headline": "Tech Sector Earnings Preview: AI Spend in Focus",
                "summary": "Major semiconductor and cloud firms set to report. CapEx guidance is the key metric for institutional investors.",
                "bucket": "general",
                "source": "MarketSniper Wire (Demo)",
                "published_utc": now.isoformat() + "Z",
                "url": "#"
            },
            {
                "id": f"demo-{date_str}-3",
                "headline": "Global Markets: Geopolitical Risk Limits Upside",
                "summary": "Tensions in key trade corridors continue to weigh on logistics stocks and energy futures.",
                "bucket": "macro",
                "source": "MarketSniper Wire (Demo)",
                "published_utc": now.isoformat() + "Z",
                "url": "#"
            },
             {
                "id": f"demo-{date_str}-4",
                "headline": "Watchlist Movers: Intraday Volume Anomalies",
                "summary": "Automated scan detection of unusual volume in key index constituents.",
                "bucket": "watchlist",
                "source": "MarketSniper Wire (Demo)",
                "published_utc": now.isoformat() + "Z",
                "url": "#"
            }
        ]
        
        payload = {
            "status": "EXISTING", # To satisfy consumers checking for "EXISTING"
            "as_of_utc": now.isoformat() + "Z",
            "source": "DEMO_GENERATOR",
            "items": items,
            "version": "1.0.0"
        }
        
        # Write to disk
        path = NewsEngine.get_artifact_path()
        path.parent.mkdir(parents=True, exist_ok=True)
        atomic_write_json(str(path), payload)
        
        return payload

    @staticmethod
    def get_news_digest() -> Dict[str, Any]:
        """
        Source Ladder Resolution:
        1. Try Reading Artifact (PIPELINE/CACHE)
        2. If Missing/Fail -> INVALID -> Generate DEMO
        3. Return Artifact
        """
        path = NewsEngine.get_artifact_path()
        
        # 1. Try Read
        if path.exists():
            # Use relative path from artifacts root for safe_read_or_fallback
            # It expects path relative to outputs/ or full path?
            # io.py: safe_read_or_fallback(filename) -> read_json_raw(filename) -> get_artifacts_root() / filename
            # So we need "engine/news_digest.json"
            
            rel_path = f"{NewsEngine.ARTIFACT_SUBDIR}/{NewsEngine.ARTIFACT_FILENAME}"
            res = safe_read_or_fallback(rel_path)
            
            if res["success"]:
                 return {
                     "status": "OK",
                     "source": "ARTIFACT_READ",
                     "payload": res["data"]
                 }
        
        # 2. Fallback: Generate Demo
        # This implicitly writes strict truth to disk too
        demo_data = NewsEngine.generate_demo_news_digest()
        
        return {
             "status": "OK", 
             "source": "DEMO_GENERATED",
             "payload": demo_data
        }
