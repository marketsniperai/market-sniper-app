import json
from datetime import datetime, timezone
from pathlib import Path

# Dynamic imports in a real system, but here strict paths
ARTIFACTS_ROOT = Path("backend/outputs")

def run_full_pipeline(run_id: str) -> list:
    """
    Generates FULL artifacts:
    - run_manifest.json
    - dashboard_market_sniper.json
    - context_market_sniper.json
    """
    ts = datetime.now(timezone.utc).isoformat()
    generated = []
    
    # 1. Manifest
    manifest = {
        "run_id": run_id,
        "build_id": "DAY_03_FULL",
        "timestamp": ts,
        "status": "LIVE_CALIBRATING",
        "pipeline_type": "FULL",
        "schema_version": "1.0"
    }
    with open(ARTIFACTS_ROOT / "run_manifest.json", "w") as f:
        json.dump(manifest, f, indent=2)
    generated.append("run_manifest.json")
    
    # 2. Dashboard
    dashboard = {
        "system_status": "LIVE",
        "message": "DAY_03_SCAFFOLD_FULL",
        "generated_at": ts,
        "widgets": [
            {"id": "W1", "type": "CARD_DELTA", "title": "Market Delta", "data": {"text": "No significant delta."}},
            {"id": "W2", "type": "CARD_WATCHLIST", "title": "Watchlist", "data": {"count": 0}}
        ]
    }
    with open(ARTIFACTS_ROOT / "dashboard_market_sniper.json", "w") as f:
        json.dump(dashboard, f, indent=2)
    generated.append("dashboard_market_sniper.json")
    
    # 3. Context
    context = {
        "summary": "Market is calibrating. Day 03 Scaffold.",
        "global_risk_score": 0.5,
        "generated_at": ts,
        "daily_stat_pack": {"vol": "low"},
        "normalization_map": {"spx": 1.0}
    }
    with open(ARTIFACTS_ROOT / "context_market_sniper.json", "w") as f:
        json.dump(context, f, indent=2)
    generated.append("context_market_sniper.json")
    
    return generated
