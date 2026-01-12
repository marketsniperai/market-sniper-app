import uvicorn
from fastapi import FastAPI, Request, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
import json
import os

# Lens Imports
from backend.artifacts.io import safe_read_or_fallback
from backend.schemas.base_models import FallbackEnvelope
from backend.schemas.manifest_schema import RunManifest
from backend.schemas.dashboard_schema import DashboardPayload
from backend.schemas.context_schema import ContextPayload
from backend.schemas.efficacy_schema import EfficacyReport
from backend.schemas.generic_schema import GenericReport
from backend.gates.core_gates import run_core_gates

# Controller Import
from backend.pipeline_controller import trigger_pipeline
import backend.stub_producers as stub_producers

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def founder_middleware(request: Request, call_next):
    response = await call_next(request)
    founder_key = request.headers.get("X-Founder-Key")
    is_founder = founder_key is not None 
    response.headers["X-Founder-Trace"] = f"FOUNDER_BUILD=TRUE; KEY_SENT={is_founder}"
    return response

# LAB / FOUNDER ENDPOINTS
@app.post("/lab/run_pipeline")
async def run_pipeline_endpoint(request: Request, background_tasks: BackgroundTasks):
    # Founder Always-On: Minimal Auth for Day 03 (Just trace presence in real app, here open for test)
    # Parse args
    body = await request.body()
    try:
        data = json.loads(body) if body else {}
    except:
        data = {}
        
    mode = data.get("mode", "AUTO")
    
    # Execute immediately for Day 03 verification (sync)
    # In real prod, this might be async, but contract says return result
    result = trigger_pipeline(mode=mode)
    
    # Also trigger stub sub-producers for now to fill truth surface
    stub_producers.generate_reports()
    
    return result

# LENS ENDPOINTS

def read_and_validate(filename: str, schema_cls):
    result = safe_read_or_fallback(filename)
    if not result["success"]:
        return FallbackEnvelope.create_fallback(result["status"], result["reason_codes"])
    try:
        payload = schema_cls(**result["data"])
        return FallbackEnvelope.create_valid(payload)
    except Exception as e:
        return FallbackEnvelope.create_fallback("SCHEMA_INVALID", [str(e)])

@app.get("/health_ext", response_model=FallbackEnvelope[RunManifest])
def health_ext():
    result = safe_read_or_fallback("run_manifest.json")
    if not result["success"]:
         return FallbackEnvelope.create_fallback(result["status"], result["reason_codes"])
    try:
        manifest = RunManifest(**result["data"])
        gates = run_core_gates(result["data"])
        envelope = FallbackEnvelope.create_valid(manifest)
        if gates["gate_status"] != "PASSED":
             envelope.status = gates["gate_status"]
             envelope.reason_codes = gates["reasons"]
        return envelope
    except Exception as e:
        return FallbackEnvelope.create_fallback("SCHEMA_INVALID", [str(e)])

@app.get("/dashboard", response_model=FallbackEnvelope[DashboardPayload])
def dashboard():
    return read_and_validate("dashboard_market_sniper.json", DashboardPayload)

@app.get("/context", response_model=FallbackEnvelope[ContextPayload])
def context():
    return read_and_validate("context_market_sniper.json", ContextPayload)

@app.get("/efficacy", response_model=FallbackEnvelope[EfficacyReport])
def efficacy():
    return read_and_validate("efficacy_report.json", EfficacyReport)

@app.get("/briefing", response_model=FallbackEnvelope[GenericReport])
def briefing():
    return read_and_validate("briefing_report.json", GenericReport)

@app.get("/aftermarket", response_model=FallbackEnvelope[GenericReport])
def aftermarket():
    return read_and_validate("aftermarket_report.json", GenericReport)

@app.get("/sunday_setup", response_model=FallbackEnvelope[GenericReport])
def sunday_setup():
    return read_and_validate("sunday_setup_report.json", GenericReport)

@app.get("/options_report", response_model=FallbackEnvelope[GenericReport])
def options_report():
    return read_and_validate("options_report.json", GenericReport)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
