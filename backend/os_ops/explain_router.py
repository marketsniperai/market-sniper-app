import json
import os
import logging
from typing import Dict, Any, Optional
from datetime import datetime

# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ExplainRouter")

# Paths
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../'))
OUTPUTS_OS_DIR = os.path.join(ROOT_DIR, 'outputs/os')
EXPLAIN_LIBRARY_PATH = os.path.join(OUTPUTS_OS_DIR, 'os_explain_library.json')
PROTOCOL_PATH = os.path.join(OUTPUTS_OS_DIR, 'os_elite_explainer_protocol.json')
ROUTER_STATUS_PATH = os.path.join(OUTPUTS_OS_DIR, 'os_explain_router_status.json')

class ExplainRouter:
    """
    D43.06: Elite Explain Router.
    Routes explanation requests safely using canonical keys and protocols.
    NO inference. NO generation.
    """

    @staticmethod
    def get_status() -> Dict[str, Any]:
        """
        Returns the current status of the Explain Router.
        Checks library integrity and artifact availability.
        Writes status to artifact.
        """
        status = {
            "timestamp_utc": datetime.utcnow().isoformat() + "Z",
            "library_loaded": False,
            "protocol_loaded": False,
            "available_keys": [],
            "unavailable_keys": [],
            "overall_status": "UNKNOWN"
        }

        # 1. Check Library
        library = ExplainRouter._load_json(EXPLAIN_LIBRARY_PATH)
        if library and "keys" in library:
            status["library_loaded"] = True
            
            # Check availability of keys (based on artifact existence)
            for key, config in library["keys"].items():
                if ExplainRouter._check_artifacts(config.get("required_artifacts", [])):
                    status["available_keys"].append(key)
                else:
                    status["unavailable_keys"].append(key)
        
        # 2. Check Protocol
        protocol = ExplainRouter._load_json(PROTOCOL_PATH)
        if protocol:
            status["protocol_loaded"] = True

        # 3. Determine Overall Status
        if status["library_loaded"] and status["protocol_loaded"]:
            status["overall_status"] = "ACTIVE" if status["available_keys"] else "DEGRADED"
        else:
            status["overall_status"] = "OFFLINE"

        # 4. Write Status Artifact
        ExplainRouter._write_json(ROUTER_STATUS_PATH, status)

        return status

    @staticmethod
    def _check_artifacts(relative_paths: list) -> bool:
        """Checks if all required artifacts exist for a key."""
        for rel_path in relative_paths:
            path = os.path.join(ROOT_DIR, rel_path)
            if not os.path.exists(path):
                return False
        return True

    @staticmethod
    def _load_json(path: str) -> Optional[Dict]:
        try:
            if os.path.exists(path):
                with open(path, 'r') as f:
                    return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load {path}: {e}")
        return None

    @staticmethod
    def _write_json(path: str, data: Dict):
        try:
            with open(path, 'w') as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to write {path}: {e}")

if __name__ == "__main__":
    # Self-Verification
    status = ExplainRouter.get_status()
    print(json.dumps(status, indent=2))
