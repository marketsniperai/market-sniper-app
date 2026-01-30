
import os
import json
import re
from typing import Dict, Any, List

from backend.os_llm.elite_llm_boundary import EliteLLMBoundary

KNOWLEDGE_INDEX_PATH = "outputs/os/os_knowledge_index.json"

class EliteChatRouter:
    """
    D49: Hybrid Chat Router (Deterministic + LLM).
    """
    
    def __init__(self):
        self.llm = EliteLLMBoundary()
        self.knowledge = {}
        self._load_knowledge()

    def _load_knowledge(self):
        if os.path.exists(KNOWLEDGE_INDEX_PATH):
            try:
                with open(KNOWLEDGE_INDEX_PATH, "r") as f:
                    data = json.load(f)
                    # Flatten modules for easier keyword search?
                    # Structure: { modules: [...], stats: ... }
                    self.knowledge = data.get("modules", [])
            except:
                print("[ChatRouter] Knowledge Index load failed.")

    def route_request(self, message: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Main routing logic.
        """
        clean_msg = message.lower().strip()
        
        # 1. Deterministic Checks (Keyword / Intent)
        
        # A. "Status" Intent
        if "status" in clean_msg or "calibrating" in clean_msg or "offline" in clean_msg:
             return self._response_deterministic(
                 answer="System Status Check",
                 sections=[
                     {"title": "System Status", "bullets": ["Operational Mode: LIVE (Simulated)", "Data Integrity: OK"]}
                 ]
             )

        # A.2 "History" / "Reflection" Intent (D49 Memory)
        if "history" in clean_msg or "reflection" in clean_msg or "past" in clean_msg or "before" in clean_msg:
            from backend.os_intel.elite_user_memory_engine import EliteUserMemoryEngine
            history = EliteUserMemoryEngine.query_history(limit=3)
            
            if not history:
                 return self._response_deterministic(
                     answer="No prior reflections found.",
                     sections=[{"title": "Memory Empty", "bullets": ["Complete a 'Daily Reflection' ritual to build history."]}]
                 )
            
            # Summarize
            bullets = []
            for h in history:
                date = h.get('date', 'Unknown')
                # Grab first answer
                answers = h.get('answers', [])
                preview = answers[0]['answer'][:50] + "..." if answers else "No detail"
                bullets.append(f"{date}: {preview}")
                
            return self._response_deterministic(
                 answer="Consulting your reflection history...",
                 sections=[
                     {"title": "Recent Reflections", "bullets": bullets}
                 ]
            )

        # B. Knowledge Index Lookup (Basic)
        # Search for module names in query
        matched_modules = []
        for mod in self.knowledge:
            mod_name = mod.get('name', '').lower()
            if mod_name and mod_name in clean_msg:
                matched_modules.append(mod)
        
        if matched_modules:
            # Construct Deterministic Response from Index
            top_match = matched_modules[0]
            return self._response_deterministic(
                answer=f"Found: {top_match['name']}",
                sections=[
                    {
                        "title": "Module Overview", 
                        "bullets": [
                            f"Type: {top_match.get('type','Unknown')}", 
                            f"Path: {top_match.get('path','Unknown') or 'N/A'}"
                        ]
                    },
                    {
                        "title": "Description",
                        "bullets": [top_match.get('description', 'No description available.')]
                    }
                ]
            )

        # 2. LLM Fallback (if applicable)
        # Simple intent check for "Explain", "Summary", "What is"
        # Or just default to LLM if it seems conversational and we have a key?
        # Implementation Plan says: "If deterministic answer exists -> NO LLM".
        # If user asks "rewrite friendly", that implies LLM.
        # Check if LLM client is viable
        if self.llm.client.model:
             llm_text = self.llm.run_safe_query(message, context)
             
             # Parse LLM text into sections if possible? 
             # For V1, we just dump text into Answer or a single section.
             return {
                 "mode": "LLM",
                 "answer": "Elite AI Response",
                 "sections": [
                     {"title": "Explanation", "bullets": [line for line in llm_text.split('\n') if line.strip()]}
                 ],
                 "next_actions": [],
                 "debug_info": {"provider": "gemini-pro"}
             }
        
        # 3. Fallback (No Match, No LLM)
        return {
             "mode": "FALLBACK",
             "answer": "I couldn't find a specific answer in the Knowledge Index.",
             "sections": [
                 {"title": "Options", "bullets": ["Try asking about a specific module.", "Ask 'System Status'.", "Check usage of 'On-Demand'."]}
             ],
             "next_actions": [],
             "debug_info": {"reason": "No match found"}
        }

    def _response_deterministic(self, answer: str, sections: List[Dict[str, Any]]) -> Dict[str, Any]:
        return {
            "mode": "DETERMINISTIC",
            "answer": answer,
            "sections": sections,
            "next_actions": [],
            "debug_info": {}
        }
