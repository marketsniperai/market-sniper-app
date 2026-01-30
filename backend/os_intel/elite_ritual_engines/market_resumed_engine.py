
from typing import Dict, Any
from datetime import datetime
from backend.os_intel.elite_ritual_engines.base_engine import EliteRitualBaseEngine

class MarketResumedEngine(EliteRitualBaseEngine):
    def __init__(self):
        super().__init__("MARKET_RESUMED", "elite_market_resumed_v1.schema.json")
        
    def _generate_payload(self) -> Dict[str, Any]:
        return {
            "meta": {
                "asOfUtc": datetime.utcnow().isoformat() + "Z",
                "source": "MarketResumedEngine",
                "version": "1.0"
            },
            "window": {
                "startEt": "16:05",
                "endEt": "16:30"
            },
            "sections": [
                {
                    "title": "Close Summary",
                    "content": "Market closed with low volatility.",
                    "type": "text"
                }
            ],
            "safety": {
                "restrictions": ["NO_OVERNIGHT_RISK_ADVICE"]
            }
        }
