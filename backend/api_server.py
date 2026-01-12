import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime, timezone
import json
import os
import uuid

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

RUN_ID = str(uuid.uuid4())
BUILD_ID = "DAY_00_INIT"
MANIFEST_PATH = "backend/outputs/run_manifest.json"

# Write Manifest
manifest = {
    "run_id": RUN_ID,
    "build_id": BUILD_ID,
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "status": "DAY_00_CALIBRATING"
}
os.makedirs("backend/outputs", exist_ok=True)
with open(MANIFEST_PATH, "w") as f:
    json.dump(manifest, f, indent=2)

@app.middleware("http")
async def founder_middleware(request, call_next):
    # Founder Always-On Logic
    response = await call_next(request)
    founder_key = request.headers.get("X-Founder-Key")
    is_founder = founder_key is not None # Simple stub for Day 00
    
    # Forensic Trace Injection
    response.headers["X-Founder-Trace"] = f"FOUNDER_BUILD=TRUE; KEY_SENT={is_founder}"
    return response

@app.get("/health_ext")
def health_ext(x_founder_key: str | None = None):
    # Stub for reading header via dependency if needed, but middleware handles trace
    return {
        "status": "CALIBRATING",
        "run_id": RUN_ID,
        "build_id": BUILD_ID,
        "server_time_utc": datetime.now(timezone.utc).isoformat(),
        "api_base_url_echo": "http://localhost:8000",
        "founder_mode": True, # Always on for Day 00
    }

@app.get("/dashboard")
def dashboard():
    return {
        "system_status": "CALIBRATING",
        "message": "DAY_00_INIT",
        "widgets": [],
        "forensic_trace": {
            "founder_build": True,
            "flags": ["FOUNDER_ALWAYS_ON"]
        }
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
