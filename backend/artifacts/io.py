import os
import json
from pathlib import Path
from typing import Optional, Any, Dict, List
from datetime import datetime

# IMMUTABLE CONTRACT: ARTIFACTS_ROOT
# Must resolve to C:\MSR\MarketSniperRepo\outputs
# The standard relative path is ../outputs from backend/artifacts/io.py
# However, this calculation is brittle if cwd varies or __file__ context is weird.
# We will make it robust.

# D62.18 PATCH: Dynamic Resolution
# Priority:
# 1. OUTPUTS_PATH env var (Source of Truth)
# 2. <repo>/backend/outputs (Writer Default)
# 3. <repo>/outputs (Legacy Fallback)

_repo_root = Path(__file__).parent.parent.parent
_env_path = os.environ.get("OUTPUTS_PATH")

if _env_path:
    ARTIFACTS_ROOT = Path(_env_path)
elif (_repo_root / "backend/outputs").exists():
    ARTIFACTS_ROOT = _repo_root / "backend/outputs"
else:
    ARTIFACTS_ROOT = _repo_root / "outputs"

def get_artifacts_root() -> Path:
    """Returns the immutable Artifacts Root."""
    root = ARTIFACTS_ROOT.resolve()
    # print(f"DEBUG: Artifacts Root: {root}")
    return root

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

def atomic_write_json(filename: str, data: Dict[str, Any]):
    """
    Writes JSON atomically: write to .tmp -> fsync -> rename.
    Ensures data integrity.
    """
    target = get_artifacts_root() / filename
    
    # D71: Residency Fix - Ensure parent directory exists
    if not target.parent.exists():
        target.parent.mkdir(parents=True, exist_ok=True)

    # Create temp file in the same directory to ensure same filesystem for rename
    # Use simple suffix
    tmp_path = target.with_suffix(".tmp")
    
    try:
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
            f.flush()
            os.fsync(f.fileno())
            
        # Atomic rename (os.replace is atomic on POSIX)
        os.replace(tmp_path, target)
    except Exception as e:
        # Cleanup
        if tmp_path.exists():
            try:
                os.remove(tmp_path)
            except:
                pass
        raise e

def append_to_ledger(filename: str, entry: Dict[str, Any]):
    """
    Appends a JSON line to a ledger file.
    Creates file if it doesn't exist.
    """
    target = get_artifacts_root() / filename
    
    # Ensure parent dir
    os.makedirs(target.parent, exist_ok=True)
    
    with open(target, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")

