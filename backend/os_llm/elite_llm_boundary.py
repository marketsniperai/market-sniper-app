
import os
import re
import json
import time
from datetime import datetime
from backend.os_llm.gemini_client import GeminiClient

LEDGER_PATH = "outputs/ledgers/llm_cost_ledger.jsonl"

class EliteLLMBoundary:
    """
    D49: Safety and Cost Boundary for LLM calls.
    - PII Scrubbing
    - Policy Injection
    - Usage Ledgering
    - Runtime Guard (Key Check)
    """
    def __init__(self):
        self.client = GeminiClient()
        self._ensure_ledger()
        
        # Runtime Guard Log (No Key Leak)
        is_available = self.client.model is not None
        print(f"[EliteLLMBoundary] ELITE_LLM_AVAILABLE={str(is_available).lower()}")
        
        # Load Policy Template
        try:
            with open("docs/canon/os_elite_chat_policy_v1.json", "r") as f:
                self.policy = json.load(f)
                self.system_template = self.policy.get("system_prompt_template", "")
        except:
            self.system_template = "You are a helpful assistant. Context: {context}. User: {user_query}"

    def _ensure_ledger(self):
        os.makedirs(os.path.dirname(LEDGER_PATH), exist_ok=True)

    def _scrub_pii(self, text: str) -> str:
        # Basic PII scrub (Email, Phone)
        # Regex for email
        text = re.sub(r'[\w\.-]+@[\w\.-]+', '[EMAIL_REDACTED]', text)
        # Regex for phone (simple US)
        text = re.sub(r'\d{3}[-\.\s]\d{3}[-\.\s]\d{4}', '[PHONE_REDACTED]', text)
        return text

    def run_safe_query(self, user_query: str, context: dict) -> str:
        """
        Executes query through boundary.
        Returns response text or fallback.
        """
        # Fallback Check
        if not self.client.model:
            # Deterministic Fallback as per Prompt
            return "OS: LLM unavailable / CALIBRATING"

        # 1. Scrub Input
        safe_query = self._scrub_pii(user_query)
        
        # 2. Construct Prompt
        screen_ctx = context.get('screen_id', 'Unknown Screen')
        sys_status = "LIVE" # Could fetch from State Snapshot
        
        full_prompt = self.system_template.format(
            screen_context=screen_ctx,
            system_status=sys_status,
            user_query=safe_query
        )
        
        # 3. Call LLM
        start_ts = time.time()
        response_text = self.client.generate_text(full_prompt)
        duration_ms = int((time.time() - start_ts) * 1000)
        
        if not response_text:
            return "OS: LLM unavailable / CALIBRATING"

        # 4. Scrub Output (Safety)
        clean_response = self._scrub_pii(response_text)

        # 5. Ledger
        self._log_usage(safe_query, len(clean_response), duration_ms)
        
        return clean_response

    def _log_usage(self, query_snippet: str, response_len: int, duration_ms: int):
        entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "query_snippet": query_snippet[:50],
            "response_len": response_len,
            "duration_ms": duration_ms,
            "provider": "Gemini"
        }
        with open(LEDGER_PATH, "a") as f:
            f.write(json.dumps(entry) + "\n")
