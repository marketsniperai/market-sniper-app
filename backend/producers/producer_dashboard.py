from datetime import datetime, timezone
from backend.ingestion.market_data import fetch_market_snapshot

def produce_dashboard(run_id: str, context: dict) -> dict:
    ts = datetime.now(timezone.utc).isoformat()
    snapshot, status = fetch_market_snapshot()
    
    # Create simple widgets based on real data
    widgets = []
    
    # 1. Delta Card
    spy_chg = snapshot.get("spy_change_pct", 0.0)
    widgets.append({
        "id": "DELTA_01",
        "type": "CARD_DELTA",
        "title": "SPY Delta",
        "data": {
            "value": f"{spy_chg:+.2f}%",
            "sentiment": "BULLISH" if spy_chg > 0 else "BEARISH"
        }
    })
    
    # 2. Status Card
    widgets.append({
        "id": "STATUS_01",
        "type": "CARD_STATUS",
        "title": "System Integrity",
        "data": {"status": "ONLINE", "run_id": run_id}
    })
    
    return {
        "system_status": "LIVE",
        "message": f"MarketSniper v0.4 ({status})",
        "widgets": widgets,
        "generated_at": ts,
        "run_manifest_ref": run_id,
        "market_snapshot": snapshot
    }
