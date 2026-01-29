
import datetime
import uuid
import hashlib
import json
from typing import Dict, Any, Optional

from backend.artifacts.io import append_to_ledger

class ReliabilityLedgerGlobal:
    """
    D48.BRAIN.04: Global Reliability Ledger.
    Tracks 'What we said' (Context Output) to compare later with 'What happened'.
    Append-Only. Source of Truth for Calibration.
    """
    
    LEDGER_PATH = "ledgers/reliability_ledger_global.jsonl"
    
    @staticmethod
    def record_entry(projection_payload: Dict[str, Any]) -> str:
        """
        Records a projection entry into the ledger.
        Returns the run_id.
        """
        run_id = str(uuid.uuid4())
        
        # 1. Extract Identity
        symbol = projection_payload.get("symbol", "UNKNOWN")
        timeframe = projection_payload.get("timeframe", "DAILY")
        as_of = projection_payload.get("asOfUtc", datetime.datetime.utcnow().isoformat())
        
        # 2. Extract State
        state = projection_payload.get("state", "UNKNOWN")
        
        # 3. Extract Scenario Summary (Non-Predictive)
        # We store the *bounds* and *volatility logic* to see if price stayed inside.
        scenarios = projection_payload.get("scenarios", {})
        base_notes = scenarios.get("base", {}).get("notes", [])
        stress_notes = scenarios.get("stress", {}).get("notes", [])
        
        # 4. Extract Attribution Pointer / Hash
        # We don't store full attribution logic to save space, but we store the hash 
        # of the attribution object if present, or key fields.
        attribution = projection_payload.get("attribution", {})
        source_ladder = attribution.get("source_ladder_used", "UNKNOWN")
        
        # create hash of full payload for integrity
        payload_str = json.dumps(projection_payload, sort_keys=True)
        payload_hash = hashlib.sha256(payload_str.encode("utf-8")).hexdigest()
        
        # 5. Construct Entry
        entry = {
            "run_id": run_id,
            "timestamp_utc": as_of,
            "recorded_at_utc": datetime.datetime.utcnow().isoformat(),
            "symbol": symbol,
            "timeframe": timeframe,
            "projection_state": state,
            "source_ladder": source_ladder,
            "payload_hash": payload_hash,
            "scenario_summary": {
                "base_notes": base_notes,
                "stress_notes": stress_notes
            },
            # Store Bounds Reference if available (e.g. Expected Move)
            "intraday_bounds": projection_payload.get("scenarios", {}).get("base", {}).get("bounds", {}),
            # Metadata
            "inputs_missing": projection_payload.get("missingInputs", [])
        }
        
        # 6. Append
        append_to_ledger(ReliabilityLedgerGlobal.LEDGER_PATH, entry)
        
        return run_id
