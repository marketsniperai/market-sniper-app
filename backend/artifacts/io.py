import os
import json
from pathlib import Path
from typing import Optional, Any, Dict, List
from datetime import datetime

# IMMUTABLE CONTRACT: ARTIFACTS_ROOT
# Must resolve to C:\MSR\MarketSniperRepo\backend\outputs
# We calculate relative to this file: backend/artifacts/io.py
# Root is ../outputs
ARTIFACTS_ROOT = Path(__file__).parent.parent / "outputs"

def get_artifacts_root() -> Path:
    """Returns the immutable Artifacts Root."""
    return ARTIFACTS_ROOT.resolve()

def read_json_raw(filename: str) -> Dict[str, Any]:
    """
    Strict read of a JSON artifact.
    Raises FileNotFoundError or JSONDecodeError if invalid.
    """
    target = get_artifacts_root() / filename
    
    # Security check: Ensure we didn't escape the root
    if get_artifacts_root() not in target.resolve().parents:
        raise ValueError(f"Security: Attempted path escape: {filename}")
        
    if not target.exists():
        raise FileNotFoundError(f"Artifact not found: {filename}")
        
    with open(target, "r", encoding="utf-8") as f:
        return json.load(f)

def safe_read_or_fallback(
    filename: str, 
    fallback_status: str = "CALIBRATING",
    fallback_reasons: Optional[List[str]] = None
) -> Dict[str, Any]:
    """
    Lens Doctrine: Never crash.
    If artifact read fails, returns a dict with 'status' and 'reason_codes' 
    that can be wrapped by the API.
    
    Note: This returns the RAW dict (either payload or partial info).
    The API layer will wrap it in FallbackEnvelope.
    """
    if fallback_reasons is None:
        fallback_reasons = []
        
    try:
        data = read_json_raw(filename)
        return {"data": data, "success": True}
    except FileNotFoundError:
        return {
            "success": False,
            "status": "MISSING_ARTIFACT",
            "reason_codes": fallback_reasons + [f"File {filename} missing"]
        }
    except json.JSONDecodeError:
        return {
            "success": False,
            "status": "DATA_CORRUPT",
            "reason_codes": fallback_reasons + [f"File {filename} is not valid JSON"]
        }
    except ValueError as e:
        return {
            "success": False,
            "status": "SECURITY_BLOCK",
            "reason_codes": fallback_reasons + [str(e)]
        }
    except Exception as e:
        return {
            "success": False,
            "status": "IO_ERROR",
            "reason_codes": fallback_reasons + [str(e)]
        }
