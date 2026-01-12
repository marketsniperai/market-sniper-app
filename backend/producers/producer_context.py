from datetime import datetime, timezone
from backend.ingestion.market_data import fetch_market_snapshot

def produce_context(run_id: str, window: str) -> dict:
    snapshot, status = fetch_market_snapshot()
    
    # Logic: minimal risk calculation based on VIX
    vix = snapshot.get("vix_level", 20.0)
    risk_score = min(max((vix - 10) / 20.0, 0.0), 1.0) # Simple normalization
    
    return {
        "summary": f"Market Regime: {snapshot.get('regime', 'UNKNOWN')}. VIX: {vix}",
        "global_risk_score": risk_score,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "daily_stat_pack": {
            "spy_change": snapshot.get("spy_change_pct", 0.0),
            "window": window
        },
        "normalization_map": {"vix_norm": risk_score}
    }
