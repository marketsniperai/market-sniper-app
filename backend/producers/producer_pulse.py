from datetime import datetime, timezone

def produce_pulse(run_id: str, mode: str, window: str) -> dict:
    return {
        "run_id": run_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "heartbeat": "OK",
        "mode": mode,
        "window": window,
        "active_modules": ["producers_v0", "autonomy_spine"]
    }
