import json
import os
from typing import List, Dict, Optional
from pydantic import BaseModel, Field

# Constants
PROTOCOL_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../outputs/os/os_elite_explainer_protocol.json'))

# Pydantic Models
class ProtocolSection(BaseModel):
    id: str
    label: str
    requirement: str
    mandatory: bool

class ToneRules(BaseModel):
    style: str
    voice: str
    prohibited: List[str]
    philosophy: str

class TierRule(BaseModel):
    structure: str
    depth: str
    allowed_sections: List[str]

class EliteExplainerProtocol(BaseModel):
    version: str
    meta_purpose: str
    sections_order: List[ProtocolSection]
    tone_rules: ToneRules
    tier_rules: Dict[str, TierRule]

class EliteExplainerProtocolReader:
    """
    Reads the Elite Explainer Protocol strictly from the filesystem.
    This serves as the configuration source for the Explain Engine.
    """

    @staticmethod
    def get_protocol() -> Optional[EliteExplainerProtocol]:
        """
        Reads and validates the protocol artifact.
        Returns None if missing or invalid.
        """
        if not os.path.exists(PROTOCOL_PATH):
            return None

        try:
            with open(PROTOCOL_PATH, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            return EliteExplainerProtocol(**data)
        except Exception as e:
            print(f"[ERROR] Failed to read Elite Explainer Protocol: {e}")
            return None

if __name__ == "__main__":
    # Quick Test
    protocol = EliteExplainerProtocolReader.get_protocol()
    if protocol:
        print(f"Protocol v{protocol.version} Loaded.")
        print(f"Sections: {[s.label for s in protocol.sections_order]}")
    else:
        print("Protocol Not Found or Invalid.")
