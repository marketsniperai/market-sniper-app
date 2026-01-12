import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime, timezone
import json
import os
import uuid

# Lens Imports
from backend.artifacts.io import safe_read_or_fallback
from backend.schemas.base_models import FallbackEnvelope
from backend.schemas.manifest_schema import RunManifest
from backend.schemas.dashboard_schema import DashboardPayload
from backend.schemas.context_schema import ContextPayload
from backend.schemas.efficacy_schema import EfficacyReport
from backend.gates.core_gates import run_core_gates

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# STUB CONSTANTS (CONTRACT)
# In a real system these might be served, but here we read manifest
RUN_ID = "LENS_BOOT" 
BUILD_ID = "DAY_02_LENS"

@app.middleware("http")
async def founder_middleware(request: Request, call_next):
    response = await call_next(request)
    founder_key = request.headers.get("X-Founder-Key")
    is_founder = founder_key is not None 
    response.headers["X-Founder-Trace"] = f"FOUNDER_BUILD=TRUE; KEY_SENT={is_founder}"
    return response

@app.get("/health_ext", response_model=FallbackEnvelope[RunManifest])
def health_ext():
    # 1. Read Manifest
    result = safe_read_or_fallback("run_manifest.json")
    
    if not result["success"]:
        return FallbackEnvelope.create_fallback(
            status=result["status"], 
            reasons=result["reason_codes"]
        )
        
    data = result["data"]
    
    # 2. Validate Schema (Lens Validation)
    try:
        manifest = RunManifest(**data)
        
        # 3. Run Gates (Logic only on validated data)
        gates = run_core_gates(data)
        
        envelope = FallbackEnvelope.create_valid(manifest)
        if gates["gate_status"] != "PASSED":
             envelope.status = gates["gate_status"]
             envelope.reason_codes = gates["reasons"]
             
        return envelope
        
    except Exception as e:
        return FallbackEnvelope.create_fallback(
            status="SCHEMA_INVALID",
            reasons=[str(e)]
        )

@app.get("/dashboard", response_model=FallbackEnvelope[DashboardPayload])
def dashboard():
    result = safe_read_or_fallback("dashboard_market_sniper.json")
    
    if not result["success"]:
        return FallbackEnvelope.create_fallback(result["status"], result["reason_codes"])

    try:
        payload = DashboardPayload(**result["data"])
        return FallbackEnvelope.create_valid(payload)
    except Exception as e:
        return FallbackEnvelope.create_fallback("SCHEMA_INVALID", [str(e)])

@app.get("/context", response_model=FallbackEnvelope[ContextPayload])
def context():
    result = safe_read_or_fallback("context_market_sniper.json")
    
    if not result["success"]:
        return FallbackEnvelope.create_fallback(result["status"], result["reason_codes"])

    try:
        payload = ContextPayload(**result["data"])
        return FallbackEnvelope.create_valid(payload)
    except Exception as e:
         return FallbackEnvelope.create_fallback("SCHEMA_INVALID", [str(e)])

@app.get("/efficacy", response_model=FallbackEnvelope[EfficacyReport])
def efficacy():
    result = safe_read_or_fallback("efficacy_report.json")
    
    if not result["success"]:
         return FallbackEnvelope.create_fallback(result["status"], result["reason_codes"])

    try:
        payload = EfficacyReport(**result["data"])
        return FallbackEnvelope.create_valid(payload)
    except Exception as e:
        return FallbackEnvelope.create_fallback("SCHEMA_INVALID", [str(e)])

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
