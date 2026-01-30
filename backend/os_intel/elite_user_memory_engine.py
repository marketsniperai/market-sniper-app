
import json
import os
import datetime
from typing import List, Dict, Any, Optional

from backend.artifacts.io import append_to_ledger, get_artifacts_root

class EliteUserMemoryEngine:
    """
    D49: Elite User Reflection Memory Engine.
    Handles storage (Local/Cloud) and retrieval of longitudinal user data.
    """
    

    LOCAL_MEMORY_PATH = "user_memory/how_you_did_local.jsonl"
    CLOUD_LEDGER_PATH = "ledgers/user_reflection_cloud.jsonl"
    SETTINGS_PATH = "config/os_settings.json"
    
    @staticmethod
    def _is_autolearn_enabled() -> bool:
        try:
             settings_path = get_artifacts_root() / EliteUserMemoryEngine.SETTINGS_PATH
             if settings_path.exists():
                 with open(settings_path, "r") as f:
                     data = json.load(f)
                     return data.get("elite_autolearn", False)
        except: pass
        return False

    @staticmethod
    def save_reflection(data: Dict[str, Any], autolearn_override: Optional[bool] = None) -> bool:
        """
        Saves reflection to Local JSONL (ALWAYS) and Cloud (IF OPT-IN).
        Refactored for Prompt 11 Compliance.
        """
        try:
            # 1. Validate Basic Fields
            if "date" not in data or "answers" not in data:
                print("[Memory] Invalid reflection data")
                return False

            # 2. Local Save (JSONL)
            # Ensure "user_memory" dir exists
            local_path = get_artifacts_root() / EliteUserMemoryEngine.LOCAL_MEMORY_PATH
            local_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Append using shared io or direct append
            # Using append_to_ledger which is effectively JSONL append
            append_to_ledger(EliteUserMemoryEngine.LOCAL_MEMORY_PATH, data)
                
            # 3. Cloud Save (Opt-In)
            should_upload = autolearn_override if autolearn_override is not None else EliteUserMemoryEngine._is_autolearn_enabled()
            
            if should_upload:
                # PII SCRUB & BUCKETING
                clean_data = {
                    "date": data.get("date"),
                    "answers": data.get("answers"), # Sanitization would happen here in full version
                    "sentiment": data.get("sentiment", "NEUTRAL"),
                    "context_snapshot": data.get("context_snapshot", {}),
                    # Remove user_id, exact timestamps if present (schema has date)
                }
                append_to_ledger(EliteUserMemoryEngine.CLOUD_LEDGER_PATH, clean_data)
                
            return True
        except Exception as e:
            import traceback
            traceback.print_exc()
            print(f"[Memory] Save Failed: {e}")
            return False

    @staticmethod
    def query_history(limit: int = 5) -> List[Dict[str, Any]]:
        """
        Retrieves last N local reflections from JSONL.
        """
        try:
            root = get_artifacts_root()
            path = root / EliteUserMemoryEngine.LOCAL_MEMORY_PATH
            if not path.exists():
                return []
            
            lines = []
            with open(path, "r", encoding="utf-8") as f:
                lines = f.readlines()
            
            # Parse and reversed return
            results = []
            for line in reversed(lines):
                try:
                    results.append(json.loads(line))
                    if len(results) >= limit: break
                except: pass
            
            return results
        except Exception as e:
            print(f"[Memory] Query Failed: {e}")
            return []

    @staticmethod
    def find_similar_scenarios(current_context: Dict[str, Any], limit: int = 3) -> List[Dict[str, Any]]:
        """
        D49 Prompt 11: Recall Logic.
        Finds past days with similar Regime/Vol context.
        """
        try:
            history = EliteUserMemoryEngine.query_history(limit=100) # Look back ~3 months
            matches = []
            
            target_regime = current_context.get("regime", "UNKNOWN")
            
            for entry in history:
                ctx = entry.get("context_snapshot", {})
                if ctx.get("regime") == target_regime:
                    matches.append(entry)
                    if len(matches) >= limit: break
            
            return matches
        except:
            return []
