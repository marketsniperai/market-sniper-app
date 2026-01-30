
import os
import json
import jsonschema
from datetime import datetime
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional

from backend.artifacts.io import get_artifacts_root, atomic_write_json
from backend.os_ops.elite_ritual_policy import EliteRitualPolicy

class EliteRitualBaseEngine(ABC):
    """
    Base class for Elite Ritual Artifact Generators.
    Enforces Window Policy and Schema Compliance.
    """
    
    def __init__(self, ritual_key: str, schema_filename: str):
        self.ritual_key = ritual_key
        self.schema_filename = schema_filename
        
    def run_and_persist(self, force_window_open: bool = False) -> Optional[Dict[str, Any]]:
        """
        Main entry point.
        1. Checks Window (unless forced).
        2. Generates payload.
        3. Validates against schema.
        4. Writes to disk.
        """
        # 1. Check Window
        if not force_window_open:
            policy = EliteRitualPolicy()
            state = policy.get_ritual_state(datetime.utcnow())
            ritual_state = state.get(self.ritual_key)
            
            if not ritual_state or not ritual_state.get("enabled"):
                print(f"[{self.ritual_key}] Window CLOSED. Skipping generation.")
                return None
                
        # 2. Generate Payload
        payload = self._generate_payload()
        
        # 3. Validate Schema
        self._validate(payload)
        
        # 4. Persist
        self._persist(payload)
        
        return payload

    @abstractmethod
    def _generate_payload(self) -> Dict[str, Any]:
        """
        Subclasses must implement this to return the strictly typed JSON payload.
        """
        pass

    def _validate(self, payload: Dict[str, Any]):
        """
        Validates payload against the JSON schema.
        """
        # ARTIFACTS_ROOT is .../outputs
        # So we look for schemas/elite/... 
        schema_path = get_artifacts_root() / "schemas" / "elite" / self.schema_filename
        
        if not schema_path.exists():
             print(f"WARNING: Schema not found at {schema_path}")
             return

        try:
            with open(schema_path, 'r') as f:
                schema = json.load(f)
            
            jsonschema.validate(instance=payload, schema=schema)
        except jsonschema.ValidationError as e:
            print(f"ERROR: Payload failed validation against {self.schema_filename}: {e.message}")
            raise e
        except Exception as e:
            print(f"ERROR: Validation Error: {e}")
            raise e

    def _persist(self, payload: Dict[str, Any]):
        filename = f"elite_{self.ritual_key.lower()}.json"
        # atomic_write_json expects path relative to artifacts root (outputs)
        relative_path = f"elite/{filename}"
        
        # Ensure directory exists
        full_output_dir = get_artifacts_root() / "elite"
        full_output_dir.mkdir(parents=True, exist_ok=True)
        
        atomic_write_json(relative_path, payload)
        print(f"[{self.ritual_key}] Artifact written to outputs/{relative_path}")
