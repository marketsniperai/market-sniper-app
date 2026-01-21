import json
import logging
from pathlib import Path
from typing import List, Dict, Optional, Tuple

# Configure logger
logger = logging.getLogger("EliteContextSafetyValidator")
logger.setLevel(logging.INFO)

PROTOCOL_PATH = Path("c:/MSR/MarketSniperRepo/outputs/os/os_elite_context_safety_protocol.json")

class EliteContextSafetyValidator:
    def __init__(self):
        self.protocol = self._load_protocol()
        
    def _load_protocol(self) -> Dict:
        if not PROTOCOL_PATH.exists():
            logger.error(f"Protocol not found at {PROTOCOL_PATH}")
            return {} # Fail safe to default strict?
        try:
            with open(PROTOCOL_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load protocol: {e}")
            return {}

    def get_fallback_message(self, key: str) -> str:
        rules = self.protocol.get("fallback_rules", {})
        return rules.get(key, "Context unavailable.")

    def validate_text(self, text: str) -> Tuple[str, bool]:
        """
        Validates text against forbidden tokens.
        Returns (safe_text, was_filtered).
        If filtered, safe_text is the fallback message.
        """
        if not text:
            return text, False
            
        forbidden = self.protocol.get("forbidden_language_tokens", [])
        text_lower = text.lower()
        
        for token in forbidden:
            # Simple token check, could be improved with regex boundary
            # but strict substring match is safer for "guarantee" etc.
            if token in text_lower:
                logger.warning(f"Safety Violation: Token '{token}' found.")
                return self.get_fallback_message("safety_violation"), True
                
        return text, False

    def validate_bullets(self, bullets: List[str]) -> Tuple[List[str], bool]:
        """
        Validates a list of bullets.
        If ANY bullet is unsafe, we filter it (or fail whole block? 
        Let's filter individual bullets to preserve utility if possible, 
        or replace with fallback if crucial).
        
        Protocol says: "If violation: Replace content with fallback".
        So we should probably nuke the specific bullet or the whole thing.
        Let's nuke the specific bullet to be "Degraded" rather than "Unavailable".
        """
        safe_bullets = []
        any_filtered = False
        
        for b in bullets:
            safe_b, filtered = self.validate_text(b)
            if filtered:
                any_filtered = True
                # Option A: Add the fallback message as a bullet
                # Option B: Drop it.
                # Let's add the fallback message so user knows why.
                safe_bullets.append(safe_b)
            else:
                safe_bullets.append(safe_b)
                
        return safe_bullets, any_filtered

    def validate_payload(self, payload: Dict) -> Tuple[Dict, bool]:
        """
        Generic payload validator. 
        Expects keys like 'bullets', 'message', 'text'.
        """
        was_filtered = False
        new_payload = payload.copy()
        
        # Micro-Briefing / Recall (bullets)
        if 'bullets' in payload and isinstance(payload['bullets'], list):
            safe_bullets, filtered = self.validate_bullets(payload['bullets'])
            new_payload['bullets'] = safe_bullets
            if filtered: was_filtered = True
            
        # What Changed / Simple Text (message)
        if 'message' in payload and isinstance(payload['message'], str):
            safe_msg, filtered = self.validate_text(payload['message'])
            new_payload['message'] = safe_msg
            if filtered: was_filtered = True

        # Explain Code (text) - if applicable
        if 'text' in payload and isinstance(payload['text'], str):
            safe_text, filtered = self.validate_text(payload['text'])
            new_payload['text'] = safe_text
            if filtered: was_filtered = True
            
        return new_payload, was_filtered
