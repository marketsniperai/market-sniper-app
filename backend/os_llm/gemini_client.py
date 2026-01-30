
import os
import google.generativeai as genai
from typing import Optional

class GeminiClient:
    """
    Minimal wrapper for Gemini API.
    Reads GEMINI_API_KEY from environment.
    """
    def __init__(self):
        self.api_key = os.environ.get("GEMINI_API_KEY")
        if self.api_key:
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel('gemini-pro')
        else:
            self.model = None

    def generate_text(self, prompt: str) -> Optional[str]:
        if not self.model:
            print("[GeminiClient] No API Key provided.")
            return None
            
        try:
            response = self.model.generate_content(prompt)
            return response.text
        except Exception as e:
            print(f"[GeminiClient] Generation Error: {e}")
            return None
