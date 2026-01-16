import os
import json
import hashlib
import uuid
import hmac
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List, Optional
from backend.artifacts.io import atomic_write_json, get_artifacts_root, safe_read_or_fallback, append_to_ledger

# TITANIUM LAW: AGMS GENERATES HANDOFF ONLY. NO EXECUTION.
NO_EXECUTION_GUARD = True

# Secret for HMAC (In prod, from env. Here simple fallback for local demo)
# DO NOT HARDCODE REAL SECRETS. This is a local repo key.
AUTOPILOT_SECRET = os.environ.get("AUTOPILOT_TOKEN_SECRET", "omsr-titanium-secret-local-dev")

class AGMSAutopilotHandoff:
    """
    Day 23: AGMS Autopilot Handoff.
    Converts Shadow Suggestions into actionable Handoff Tokens.
    
    Responsibilities:
    1. Read Shadow Suggestions.
    2. Select Top Candidate (if High Confidence).
    3. Generate HMAC Token.
    4. Write Handoff Artifact (Target for Autofix).
    
    Constraint: NO EXECUTION CALLS.
    """
    
    AGMS_ROOT = "runtime/agms"
    
    @staticmethod
    def generate_handoff() -> Dict[str, Any]:
        """
        Main entry point.
        """
        assert NO_EXECUTION_GUARD is True, "AGMS MUST NOT EXECUTE"
        
        root = get_artifacts_root()
        now = datetime.now(timezone.utc)
        
        # 1. READ SUGGESTIONS
        # We read the snapshot or suggestions artifact
        sug_res = safe_read_or_fallback("runtime/agms/agms_shadow_suggestions.json")
        suggestions_data = sug_res.get("data", {})
        suggestions = suggestions_data.get("suggestions", [])
        
        handoff = None
        
        # 2. SELECT CANDIDATE
        # Criteria: Top suggestion, High/Med severity, Confidence > 0.6
        if suggestions:
            candidate = suggestions[0]
            if candidate.get("confidence", 0) > 0.6:
                handoff = AGMSAutopilotHandoff._create_handoff_payload(candidate, now)
        
        # 3. PERSIST ARTIFACTS
        AGMSAutopilotHandoff._persist_artifacts(root, handoff, now)
        
        return {"handoff": handoff, "status": "GENERATED" if handoff else "NO_CANDIDATE"}

    @staticmethod
    def _create_handoff_payload(candidate: Dict[str, Any], now: datetime) -> Dict[str, Any]:
        handoff_id = str(uuid.uuid4())
        playbook_id = candidate["mapped_playbook_id"]
        
        # Token Generation (HMAC)
        # Token = HMAC(SECRET, handoff_id + playbook_id + date_bucket)
        # Date bucket ensures token expires effectively if logic changes or rotation
        date_bucket = now.strftime("%Y%m%d") 
        msg = f"{handoff_id}:{playbook_id}:{date_bucket}"
        token = hmac.new(
            AUTOPILOT_SECRET.encode("utf-8"),
            msg.encode("utf-8"),
            hashlib.sha256
        ).hexdigest()
        
        return {
            "handoff_id": handoff_id,
            "timestamp_utc": now.isoformat(),
            "suggested_playbook_id": playbook_id,
            "action_code": "RUN_PIPELINE_HANDOFF", # Generic opcode for Autofix
            "confidence": candidate["confidence"],
            "severity": candidate["severity"],
            "token": token,
            "evidence_refs": [candidate["suggestion_id"]]
        }

    @staticmethod
    def _persist_artifacts(root: Path, handoff: Optional[Dict[str, Any]], now: datetime):
        agms_dir = root / AGMSAutopilotHandoff.AGMS_ROOT
        
        # 1. Latest Handoff
        # If None, we might write null or just skip update? 
        # Writing null clears state which is good.
        atomic_write_json(str(agms_dir / "agms_handoff.json"), {
            "timestamp_utc": now.isoformat(),
            "handoff": handoff
        })
        
        # 2. Ledger Append (Only if handoff exists)
        if handoff:
            entry = {
                "timestamp_utc": handoff["timestamp_utc"],
                "handoff_id": handoff["handoff_id"],
                "playbook_id": handoff["suggested_playbook_id"],
                "token_prefix": handoff["token"][:8] + "..."
            }
            append_to_ledger("runtime/agms/agms_handoff_ledger.jsonl", entry)
            
    # Verification Helper
    @staticmethod
    def verify_token(handoff: Dict[str, Any]) -> bool:
        """
        Public helper for Autofix to re-validate token logic match.
        Autofix will import this or implement identical logic.
        """
        if not handoff: return False
        
        secret = os.environ.get("AUTOPILOT_TOKEN_SECRET", "omsr-titanium-secret-local-dev")
        ts = datetime.fromisoformat(handoff["timestamp_utc"].replace("Z", "+00:00"))
        date_bucket = ts.strftime("%Y%m%d")
        
        msg = f"{handoff['handoff_id']}:{handoff['suggested_playbook_id']}:{date_bucket}"
        expected = hmac.new(
            secret.encode("utf-8"), 
            msg.encode("utf-8"), 
            hashlib.sha256
        ).hexdigest()
        return hmac.compare_digest(expected, handoff["token"])
