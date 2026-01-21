import json
import os
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from pydantic import BaseModel

from backend.os_ops.elite_context_engine_status_reader import EliteContextEngineStatusReader

# Constants
PATH_PROTOCOL = "outputs/os/os_elite_micro_briefing_protocol.json"
PATH_CONTEXT = "outputs/context/context_market_sniper.json"
PATH_RISK = "outputs/os/global_risk_state.json"
PATH_MANIFEST = "outputs/run_manifest.json"

class EliteMicroBriefingSnapshot(BaseModel):
    timestamp_utc: str
    window: str = "OPEN"
    engine_status: str # LIVE | STALE | LOCKED | UNAVAILABLE
    bullets: List[str]
    boundary: str

class EliteMicroBriefingEngine:
    
    def generate_briefing(self) -> Optional[EliteMicroBriefingSnapshot]:
        # 1. Check Protocol
        if not os.path.exists(PATH_PROTOCOL):
            return None
            
        try:
            with open(PATH_PROTOCOL, 'r') as f:
                protocol = json.load(f)
        except:
            return None
            
        boundary = protocol.get("boundary_text", "---")
        max_bullets = protocol.get("max_bullets", 3)
        
        # 2. Check Engine Status
        status_reader = EliteContextEngineStatusReader()
        status_snap = status_reader.get_status()
        
        engine_status = status_snap.status if status_snap else "UNAVAILABLE"
        
        now_utc = datetime.now(timezone.utc).isoformat()
        bullets = []

        # 3. Degraded Mode (If not LIVE)
        if engine_status != "LIVE":
            # Return degraded briefing
            bullets.append(f"STATUS: {engine_status}")
            if status_snap and status_snap.reason_code:
                bullets.append(f"REASON: {status_snap.reason_code}")
                
            return EliteMicroBriefingSnapshot(
                timestamp_utc=now_utc,
                engine_status=engine_status,
                bullets=bullets,
                boundary=boundary
            )

        # 4. LIVE Mode - Read Artifacts
        # We need "Drivers" (Risk), "Watch" (Context), "OS" (Status/Risk)
        
        # Read Context
        context_data = {}
        if os.path.exists(PATH_CONTEXT):
            try:
                with open(PATH_CONTEXT, 'r') as f:
                    context_data = json.load(f)
            except:
                pass
        
        # Read Risk
        risk_data = {}
        if os.path.exists(PATH_RISK):
            try:
                with open(PATH_RISK, 'r') as f:
                    risk_data = json.load(f)
            except:
                pass

        # 5. Construct Bullets (Strict Mirroring)
        
        # Bullet 1: Drivers (Risk State)
        # e.g. "Risk: FRACTURED (VIX 25.4)"
        risk_state = risk_data.get("risk_state", "UNKNOWN")
        vix = risk_data.get("vix_level", "N/A")
        bullets.append(f"Risk Condition: {risk_state} (VIX: {vix})")
        
        # Bullet 2: What to watch (Context focus)
        # e.g. "Focus: SPY, NVDA"
        focus_list = context_data.get("focus_tickers", [])
        if focus_list:
            focus_str = ", ".join(focus_list[:3]) # Limit to 3
            bullets.append(f"Focus: {focus_str}")
        else:
             # Fallback if no focus
             bullets.append("Focus: General Market Surveillance")
        
        # Bullet 3: OS / Status
        # e.g. "Engine: LIVE (Active Recon)"
        # Or maybe active stage from manifest?
        # Let's stick to Status unless we have something better.
        bullets.append(f"Engine: {engine_status} (Systems Nominal)")

        # Enforce Max Bullets
        bullets = bullets[:max_bullets]

        return EliteMicroBriefingSnapshot(
            timestamp_utc=now_utc,
            engine_status=engine_status,
            bullets=bullets,
            boundary=boundary
        )
