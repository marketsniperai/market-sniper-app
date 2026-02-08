from fastapi import Request, Header, HTTPException
from typing import Optional
import os
import time
import json
import sys
from pathlib import Path
from backend.config import BackendConfig

# Rate Limit Config
MAX_DAILY_COST_REQUESTS_PLUS = 20
MAX_DAILY_COST_REQUESTS_ELITE = 9999
RATE_LIMIT_FILE = Path("outputs/runtime/elite/elite_rate_limit_state.json")

class EliteGate:
    def __init__(self):
        self._ensure_rate_limit_file()

    def _ensure_rate_limit_file(self):
        if not RATE_LIMIT_FILE.parent.exists():
            RATE_LIMIT_FILE.parent.mkdir(parents=True, exist_ok=True)
        if not RATE_LIMIT_FILE.exists():
            with open(RATE_LIMIT_FILE, "w") as f:
                json.dump({}, f)

    def is_founder(self, request: Request) -> bool:
        env_key = BackendConfig.FOUNDER_KEY
        headers = request.headers
        req_key = headers.get("X-Founder-Key")
        
        # Strict Check
        if env_key and req_key and req_key == env_key:
            return True
        return False

    def is_elite_entitled(self, request: Request) -> bool:
        env = os.getenv("ENV", "")
        header = request.headers.get("X-Test-Elite-Entitled", "")
        
        # Local / Test Override ONLY
        if env.lower() == "local" and header == "TRUE":
            return True
            
        # TODO: Implement real entitlement check (JWT/DB)
        return False

    def check_rate_limit(self, request: Request, key: str = "default"):
        # 1. Bypass
        if self.is_founder(request):
            return 

        if self.is_elite_entitled(request):
             return 

        # 2. Key Generation (IP + Date)
        client_ip = request.client.host if request.client else 'unknown'
        today = time.strftime("%Y-%m-%d")
        composite_key = f"{today}:{client_ip}"

        # 3. Load State
        try:
             with open(RATE_LIMIT_FILE, "r") as f:
                 data = json.load(f)
        except:
             data = {}

        # 4. Check & Inc
        count = data.get(composite_key, 0)
        
        # Limit for Non-Elite/Non-Founder (Plus Tier?)
        # Currently Policy says blocked by Auth anyway, but if we open up:
        limit = MAX_DAILY_COST_REQUESTS_PLUS
        
        if count >= limit:
             print(f"ELITE_GATE: RATE_LIMIT ip={client_ip} count={count}")
             raise HTTPException(status_code=429, detail="RATE_LIMIT_EXCEEDED")
        
        data[composite_key] = count + 1
        
        # 5. Save State
        try:
            with open(RATE_LIMIT_FILE, "w") as f:
                json.dump(data, f)
        except Exception as e:
            print(f"ELITE_GATE: Failed to save rate limit: {e}")

    def require_elite_or_founder(self, request: Request):
        """
        Dependency for FastAPI routes.
        Raises HTTPException(403) if not authorized.
        """
        # 1. Founder Override
        if self.is_founder(request):
             return # ALLOW
        
        # 2. Elite Entitlement
        if self.is_elite_entitled(request):
             return # ALLOW

        # 3. Fail Closed
        client_ip = request.client.host if request.client else 'unknown'
        path = request.url.path
        print(f"ELITE_GATE: DENY ip={client_ip} path={path}")
        # sys.stdout.flush() # Keep logs clean unless debugging
        raise HTTPException(status_code=403, detail="NOT_AUTHORIZED")

# Singleton
elite_gate = EliteGate()

async def require_elite_or_founder(request: Request):
    elite_gate.require_elite_or_founder(request)
