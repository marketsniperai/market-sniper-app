import json
from pathlib import Path
from backend.os_ops.autofix_tier1 import DECISION_PATH_PATH

class AutoFixDecisionReader:
    @staticmethod
    def get_decision_path() -> dict:
        """
        Reads the latest AutoFix Decision Path artifact.
        Returns deserialized JSON or None if missing.
        Using dict instead of Pydantic model at boundary to avoid coupling API to internal logic if simpler,
        but returning dict matches API usage directly.
        """
        if not DECISION_PATH_PATH.exists():
            return None
        
        try:
            with open(DECISION_PATH_PATH, "r") as f:
                return json.load(f)
        except Exception:
            return None
