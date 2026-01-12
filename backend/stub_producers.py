import json
from datetime import datetime, timezone
from pathlib import Path

ARTIFACTS_ROOT = Path("backend/outputs")

def generate_reports():
    ts = datetime.now(timezone.utc).isoformat()
    
    # Briefing
    briefing = {
        "run_id": "STUB",
        "timestamp": ts,
        "audio_url": None,
        "transcript": "Briefing system calibrating."
    }
    with open(ARTIFACTS_ROOT / "briefing_report.json", "w") as f:
        json.dump(briefing, f, indent=2)
        
    # Aftermarket
    aftermarket = {
        "run_id": "STUB",
        "timestamp": ts,
        "summary": "Aftermarket system calibrating."
    }
    with open(ARTIFACTS_ROOT / "aftermarket_report.json", "w") as f:
        json.dump(aftermarket, f, indent=2)
        
    # Sunday Setup
    sunday = {
        "run_id": "STUB",
        "timestamp": ts,
        "week_ahead": "Calibration week."
    }
    with open(ARTIFACTS_ROOT / "sunday_setup_report.json", "w") as f:
        json.dump(sunday, f, indent=2)
        
    # Efficacy
    efficacy = {
        "report_id": "STUB",
        "generated_at": ts,
        "overall_win_rate": 0.0,
        "total_trades": 0,
        "ledger": []
    }
    with open(ARTIFACTS_ROOT / "efficacy_report.json", "w") as f:
        json.dump(efficacy, f, indent=2)
        
    # Options
    options = {
        "run_id": "STUB",
        "generated_at": ts,
        "chain_summary": "No options usage."
    }
    with open(ARTIFACTS_ROOT / "options_report.json", "w") as f:
        json.dump(options, f, indent=2)

if __name__ == "__main__":
    generate_reports()
