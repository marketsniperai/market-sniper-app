
import os
import sys
from datetime import datetime
from typing import Dict, Any, Optional

# Add repo root to path if needed (standard pattern)
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if REPO_ROOT not in sys.path:
    sys.path.append(REPO_ROOT)

from backend.os_ops.elite_ritual_policy import EliteRitualPolicy
from backend.artifacts.io import safe_read_or_fallback, get_artifacts_root

# Import Engines
from backend.os_intel.elite_ritual_engines.morning_briefing_engine import MorningBriefingEngine
from backend.os_intel.elite_ritual_engines.midday_report_engine import MiddayReportEngine
from backend.os_intel.elite_ritual_engines.market_resumed_engine import MarketResumedEngine
from backend.os_intel.elite_ritual_engines.how_i_did_today_engine import HowIDidTodayEngine
from backend.os_intel.elite_ritual_engines.how_you_did_today_engine import HowYouDidTodayEngine
from backend.os_intel.elite_ritual_engines.sunday_setup_engine import SundaySetupEngine

class EliteRitualRouter:
    """
    D49: Central Router for Elite Rituals.
    Handles Policy checks, Lazy Generation, and Standardized Responses.
    """
    
    def __init__(self):
        self.policy = EliteRitualPolicy()
        self.engines = {
            "morning_briefing": MorningBriefingEngine,
            "midday_report": MiddayReportEngine,
            "mid_day_report": MiddayReportEngine, # Alias support
            "market_resumed": MarketResumedEngine,
            "how_i_did_today": HowIDidTodayEngine,
            "how_you_did_today": HowYouDidTodayEngine,
            "sunday_setup": SundaySetupEngine
        }

    def route(self, ritual_id: str) -> Dict[str, Any]:
        """
        Main entry point.
        Returns a standardised envelope:
        {
          "ritual_id": str,
          "status": "OK" | "WINDOW_CLOSED" | "CALIBRATING" | "OFFLINE",
          "as_of_utc": str,
          "payload": dict | None
        }
        """
        # 1. Normalize ID
        rid = ritual_id.lower()
        if rid not in self.engines:
             return self._envelope(rid, "OFFLINE", None, details="Unknown Ritual ID")

        # 2. Check Policy
        state_map = self.policy.get_ritual_state(datetime.utcnow())
        # Ritual IDs in policy might match keys exactly
        # Policy keys: morning_briefing, mid_day_report, market_resumed, how_i_did_today, how_you_did_today, sunday_setup
        r_state = state_map.get(rid)
        
        # If alias fallback
        if not r_state and rid == "midday_report":
             r_state = state_map.get("mid_day_report")

        if not r_state:
             # Should not happen if confirmed in engines map, but sagecheck
             return self._envelope(rid, "OFFLINE", None, details="Policy Definition Missing")

        # 3. Handle Visibility/Enabled
        # Per prompt: "si window closed -> return WINDOW_CLOSED"
        # We define "Window Open" as enabled=True (Active Window in Policy)
        # However, we also have 'visible=True' (e.g. Always Visible).
        # If Always Visible, we should return the artifact if it exists, even if window closed?
        # Prompt says: "si window closed -> devuelve status WINDOW_CLOSED".
        # But if it's "Always Visible" (like Morning Briefing from 10am until next day?), usually we show the LAST content.
        # But the Requirement says "if window closed -> WINDOW_CLOSED". This acts like a strict gating.
        # Let's look at the Policy logic again.
        # morning_briefing: "visibility": "always". "type": "daily", "start": "09:20", "end": "09:50".
        # If it is 10:00 AM, enabled is False. Visible is True.
        # Use Case: User wants to see Morning Briefing at 10:00 AM.
        # If we return WINDOW_CLOSED, the requested Modal shows "WINDOW CLOSED". 
        # That contradicts "always visible".
        # Logic Interpretation:
        # "WINDOW_CLOSED" is for when we literally deny access (e.g. Sunday Setup on Tuesday).
        # If Visible=True, we should try to serve content.
        # So:
        # If NOT Visible: return WINDOW_CLOSED.
        # If Visible:
        #    Proceed to check artifact.
        
        if not r_state.get('visible', False):
             return self._envelope(rid, "WINDOW_CLOSED", None)
             
        # 4. Check Artifact
        # Artifact path: outputs/elite/elite_{id}.json
        # Note: mid_day_report alias might need normalized filename
        # Engine writes to 'elite_{key}.json'.
        # We need to know what key the engine uses.
        # The engine class usually knows its key or we instantiate it.
        # Let's instantiate the engine to be sure of keys if needed, or just guess.
        # Actually, let's look for the file first to be fast.
        # Filename convention: elite_{ritual_id}.json
        # But wait, policy uses 'mid_day_report', engine might use 'midday_report'?
        # Let's check 'midday_report_engine.py' -> schema "elite_midday_report.json"? 
        # No, base engine uses self.ritual_key.
        # MorningBriefingEngine: ritual_key="MORNING_BRIEFING" -> elite_morning_briefing.json
        # MiddayReportEngine: ritual_key="MIDDAY_REPORT" -> elite_midday_report.json
        # So it uses the enum/key from constructor.
        
        # We might need to map requests to exact filenames.
        filename_map = {
            "morning_briefing": "elite_morning_briefing.json",
            "midday_report": "elite_midday_report.json",
            "mid_day_report": "elite_midday_report.json", 
            "market_resumed": "elite_market_resumed.json",
            "how_i_did_today": "elite_how_i_did_today.json",
            "how_you_did_today": "elite_how_you_did_today.json",
            "sunday_setup": "elite_sunday_setup.json"
        }
        
        target_file = filename_map.get(rid)
        full_path = f"outputs/elite/{target_file}"
        
        res = safe_read_or_fallback(full_path)
        
        if res['success']:
             # Found it!
             # BUT, is it STALE?
             # Policy engine doesn't enforce freshness for 'Always Visible' explicitly, 
             # but we assume the last generated one is valid until overwritten.
             return self._envelope(rid, "OK", res['data'])
        
        # 5. Missing Artifact -> Lazy Generation
        # Only if 'enabled' (Time Window is currently open).
        # If we are outside the window (enabled=False), but Visible=True, and file is missing:
        # We cannot generate it (data might be gone or inappropriate time).
        # So return OFFLINE or CALIBRATING or FALLBACK.
        
        if r_state.get('enabled', False):
             # Window is OPEN. We can Generate.
             files_generated = self._run_generation(rid)
             if files_generated:
                 # Read again
                 res2 = safe_read_or_fallback(full_path)
                 if res2['success']:
                      return self._envelope(rid, "OK", res2['data'])
                 else:
                      return self._envelope(rid, "CALIBRATING", None, details="Generation produced no file")
             else:
                 return self._envelope(rid, "CALIBRATING", None, details="Generation failed")
        
        # 6. Visible but Missing and Not Enabled (e.g. Cleared out, or first run / error)
        # Return CALIBRATING as a polite fallback
        return self._envelope(rid, "CALIBRATING", None, details="Visible but missing and outside window")

    def _run_generation(self, rid: str) -> bool:
        """
        Instantiates and runs the specific engine.
        Returns True if successful.
        """
        engine_cls = self.engines.get(rid)
        if not engine_cls:
            return False
            
        try:
            # Instantiate and Run
            # Engines follow standard interface? run() -> void (persists)
            engine = engine_cls()
            engine.run()
            return True
        except Exception as e:
            # Log error?
            print(f"[RiteRouter] Generation Error for {rid}: {e}")
            return False

    def _envelope(self, rid: str, status: str, payload: Any, details: str = None) -> Dict[str, Any]:
        return {
            "ritual_id": rid,
            "status": status,
            "as_of_utc": datetime.utcnow().isoformat() + "Z",
            "payload": payload,
            "details": details
        }
