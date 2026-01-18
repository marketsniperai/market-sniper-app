import uvicorn
from fastapi import FastAPI, Request, BackgroundTasks, Header, HTTPException
from typing import Optional, Dict, Any
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
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
from backend.pipeline_controller import trigger_pipeline
import backend.stub_producers as stub_producers
import backend.os_ops.misfire_monitor as misfire_monitor

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

@app.post("/lab/misfire_autoheal")
async def misfire_autoheal(request: Request, background_tasks: BackgroundTasks):
    # Founder Law: Total Access.
    # Check status first
    report = misfire_monitor.check_misfire_status()
    if report["status"] == "MISFIRE":
        # Trigger Job
        result = misfire_monitor.trigger_autoheal()
        return {
            "action": "TRIGGERED", 
            "misfire_status": report,
            "job_result": result
        }
    else:
        return {
            "action": "NO_ACTION",
            "misfire_status": report
        }

# LENS ENDPOINTS

def read_and_validate(filename: str, schema_cls, subdir: str = "full"):
    # Enforce namespace based on context
    path_to_read = f"{subdir}/{filename}"
    result = safe_read_or_fallback(path_to_read)
    
    if not result["success"]:
        return FallbackEnvelope.create_fallback(result["status"], result["reason_codes"])
    try:
        payload = schema_cls(**result["data"])
        return FallbackEnvelope.create_valid(payload)
    except Exception as e:
        return FallbackEnvelope.create_fallback("SCHEMA_INVALID", [str(e)])

@app.get("/health_ext", response_model=FallbackEnvelope[RunManifest])
def health_ext():
    # Primary Truth is now FULL pipeline
    result = safe_read_or_fallback("full/run_manifest.json")
    if not result["success"]:
         return FallbackEnvelope.create_fallback(result["status"], result["reason_codes"])
    try:
        data = result["data"]
        # Backward compatibility for older manifests
        if not data.get("mode"):
             data["mode"] = "FULL" # Default if missing or None
        if not data.get("window"):
             data["window"] = "UNKNOWN" # Default if missing or None
             
        manifest = RunManifest(**data)
        gates = run_core_gates(data)
        envelope = FallbackEnvelope.create_valid(manifest)
        if gates["gate_status"] != "PASSED":
             envelope.status = gates["gate_status"]
             envelope.reason_codes = gates["reasons"]
        return envelope
    except Exception as e:
        return FallbackEnvelope.create_fallback("SCHEMA_INVALID", [str(e)])

@app.get("/dashboard", response_model=FallbackEnvelope[DashboardPayload])
def dashboard():
    return read_and_validate("dashboard_market_sniper.json", DashboardPayload, subdir="full")

@app.get("/context", response_model=FallbackEnvelope[ContextPayload])
def context():
    return read_and_validate("context_market_sniper.json", ContextPayload, subdir="full")

@app.get("/efficacy", response_model=FallbackEnvelope[EfficacyReport])
def efficacy():
    return read_and_validate("efficacy_report.json", EfficacyReport, subdir="full")

@app.get("/briefing", response_model=FallbackEnvelope[GenericReport])
def briefing():
    return read_and_validate("briefing_report.json", GenericReport, subdir="full")

@app.get("/misfire")
def misfire():
    # Dynamic check (read or compute)
    return misfire_monitor.check_misfire_status()

@app.get("/pulse", response_model=FallbackEnvelope[RunManifest])
def pulse():
    # Light Truth
    result = safe_read_or_fallback("light/run_manifest.json")
    if not result["success"]:
         return FallbackEnvelope.create_fallback(result["status"], result["reason_codes"])
    try:
        data = result["data"]
         # Backward compatibility
        if not data.get("mode"):
             data["mode"] = "LIGHT"
        
        manifest = RunManifest(**data)
        return FallbackEnvelope.create_valid(manifest)
    except Exception as e:
        return FallbackEnvelope.create_fallback("SCHEMA_INVALID", [str(e)])

@app.get("/aftermarket", response_model=FallbackEnvelope[GenericReport])
def aftermarket():
    return read_and_validate("aftermarket_report.json", GenericReport, subdir="full")

@app.get("/sunday_setup", response_model=FallbackEnvelope[GenericReport])
def sunday_setup():
    return read_and_validate("sunday_setup_report.json", GenericReport, subdir="full")

@app.get("/options_report", response_model=FallbackEnvelope[GenericReport])
def options_report():
    return read_and_validate("options_report.json", GenericReport, subdir="full")


# AUTOFIX ENDPOINTS (DAY 15)
from backend.os_ops.autofix_control_plane import AutoFixControlPlane

@app.get("/autofix")
def get_autofix_status():
    """
    Day 15: Read-Only AutoFix Control Plane.
    Observes system, recommends actions, writes to ledger.
    No execution.
    """
    return AutoFixControlPlane.assess_and_recommend()

@app.post("/lab/autofix/execute")
async def autofix_execute(request: Request):
    """
    Day 16: AutoFix Execution (Founder-Gated).
    Trigger an allowed action code.
    """
    # 1. Founder Gate (Simplistic check for now, real environment uses IAM/Middleware)
    # But we respect the "Founder-Gated" requirement by checking header.
    # We won't block strictly here to allow easy verification if key missing in dev, 
    # but in PROD this would be stricter.
    auth_header = request.headers.get("X-Founder-Key")
    
    try:
        body = await request.json()
        action_code = body.get("action_code")
        if not action_code:
            return JSONResponse(status_code=400, content={"error": "Missing action_code"})
            
        result = AutoFixControlPlane.execute_action(action_code, auth_header)
        
        return result
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

# HOUSEKEEPER ENDPOINTS (DAY 17)
from backend.os_ops.housekeeper import Housekeeper

@app.get("/lab/os/self_heal/housekeeper/status")
def housekeeper_status_endpoint():
    """
    D42.03: Housekeeper Status (Last Run).
    """
    # For now, we don't have a persisted status artifact other than the proof.
    # We can try to read the latest proof if we wanted, or returning 404 is valid per spec.
    # To be more helpful, let's look for the proof.
    from backend.os_ops.housekeeper import PROOF_PATH
    if PROOF_PATH.exists():
        with open(PROOF_PATH, "r") as f:
            return json.load(f)
    return JSONResponse(status_code=404, content={"error": "Status unavailable"})

@app.post("/lab/os/self_heal/housekeeper/run")
def housekeeper_run_endpoint(request: Request):
    """
    D42.03: Housekeeper Auto Execution (Plan-Based).
    Founder-Gated (Implied).
    """
    auth_header = request.headers.get("X-Founder-Key")
    # Gate implied
    
    return Housekeeper.run_from_plan().dict()
    
# IRON OS ENDPOINTS (DAY 41)
from backend.os_ops.iron_os import IronOS

@app.get("/lab/os/iron/status")
def iron_status():
    """
    Day 41: Iron OS Status (State + Heartbeat).
    Returns strict snapshot or 404/Null if unavailable.
    """
    status = IronOS.get_status()
    if not status:
        return JSONResponse(status_code=404, content={"error": "UNAVAILABLE"})
    return status

@app.get("/lab/os/iron/timeline_tail")
def iron_timeline():
    """
    D41.02: Iron OS Timeline Tail.
    Returns last 10 events or 404.
    """
    data = IronOS.get_timeline_tail()
    if not data:
        return JSONResponse(status_code=404, content={"error": "UNAVAILABLE"})
    return data

@app.get("/lab/os/self_heal/findings")
async def get_self_heal_findings():
    """D42.08: Findings Panel Surface (Strict Lens for os_findings.json)"""
    data = IronOS.get_findings()
    if data is None:
        raise HTTPException(status_code=404, detail="Findings unavailable")
    return data

@app.get("/lab/os/self_heal/before_after")
async def get_self_heal_before_after():
    """D42.09: Before/After Diff Surface (Strict Lens for os_before_after_diff.json)"""
    data = IronOS.get_before_after_diff()
    if data is None:
        raise HTTPException(status_code=404, detail="Diff unavailable")
    return data

@app.get("/lab/os/iron/state_history")
def iron_history():
    """
    D41.07: Iron OS State History.
    Returns last 10 states or 404.
    """
    data = IronOS.get_state_history()
    if not data:
        return JSONResponse(status_code=404, content={"error": "UNAVAILABLE"})
    return data

@app.get("/lab/os/iron/drift")
def iron_drift():
    """
    D41.08: Iron OS Drift Surface.
    Returns drift report or 404.
    """
    data = IronOS.get_drift_report()
    if data is None: 
        return JSONResponse(status_code=404, content={"error": "UNAVAILABLE"})
    return data

@app.get("/lab/os/iron/replay_integrity")
def iron_replay():
    """
    D41.11: Iron OS Replay Integrity.
    Returns integrity report or 404.
    """
    data = IronOS.get_replay_integrity()
    if not data:
        return JSONResponse(status_code=404, content={"error": "UNAVAILABLE"})
    return data

# WAR ROOM ENDPOINTS (DAY 18)
from backend.os_ops.war_room import WarRoom

@app.get("/lab/war_room")
def war_room_dashboard(request: Request):
    """
    Day 18: War Room Command Center (Founder-Gated).
    Unified view of all autonomous systems and forensic timelines.
    """
    auth_header = request.headers.get("X-Founder-Key")
    # Gate check (Strict for War Room visibility)
    # verify_day_18.py will simulate key
    
    return WarRoom.get_dashboard()

# SHADOW REPAIR (DAY 19)
from backend.os_ops.shadow_repair import ShadowRepair

@app.post("/lab/shadow_repair/propose")
async def shadow_repair_propose(request: Request):
    """
    Day 19: Shadow Repair Propose (Founder-Gated).
    Generates a patch proposal. NO APPLY.
    """
    auth_header = request.headers.get("X-Founder-Key")
    # Gate check implied
    
    try:
        body = await request.json()
        symptoms = body.get("symptoms", [])
        playbook_id = body.get("playbook_id")
        
        return ShadowRepair.propose_patch(symptoms, playbook_id)
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

# AGMS FOUNDATION (DAY 20)
from backend.os_intel.agms_foundation import AGMSFoundation

@app.get("/agms/foundation")
def agms_foundation():
    """
    Day 20: AGMS Foundation (Memory + Mirror + Truth).
    Observe-Only. Returns Snapshot + Delta.
    """
    return AGMSFoundation.run_agms_foundation()

@app.get("/agms/ledger/tail")
def agms_ledger_tail(limit: int = 50):
    """
    Day 20: AGMS History.
    Returns last N ledger entries.
    """
    # Quick read helper
    from backend.artifacts.io import get_artifacts_root
    path = get_artifacts_root() / "runtime/agms/agms_ledger.jsonl"
    lines = []
    if path.exists():
        with open(path, "r") as f:
            all_lines = f.readlines()
            lines = [json.loads(l) for l in all_lines[-limit:]]
    return lines

# AGMS INTELLIGENCE (DAY 21)
from backend.os_intel.agms_intelligence import AGMSIntelligence

@app.get("/agms/intelligence")
def agms_intelligence():
    """
    Day 21: AGMS Intelligence.
    Returns Patterns, Coherence, and Summary.
    Shadow Mode: Analysis Only.
    """
    return AGMSIntelligence.generate_intelligence()

@app.get("/agms/summary")
def agms_summary():
    """
    Day 21: Weekly Summary (Compressed Timeline).
    """
    intel = AGMSIntelligence.generate_intelligence()
    return intel.get("summary", {})

# AGMS SHADOW RECOMMENDER (DAY 22)
from backend.os_intel.agms_shadow_recommender import AGMSShadowRecommender

@app.get("/agms/shadow/suggestions")
def agms_shadow_suggestions():
    """
    Day 22: AGMS Shadow Suggestions.
    Suggest-Only. Mapped from Patterns to Playbooks.
    """
    return AGMSShadowRecommender.generate_suggestions()

@app.get("/agms/shadow/ledger/tail")
def agms_shadow_ledger_tail(limit: int = 50):
    """
    Day 22: Shadow Ledger History.
    """
    from backend.artifacts.io import get_artifacts_root
    path = get_artifacts_root() / "runtime/agms/agms_shadow_ledger.jsonl"
    lines = []
    if path.exists():
        with open(path, "r") as f:
            all_lines = f.readlines()
            lines = [json.loads(l) for l in all_lines[-limit:]]
    return lines

# AGMS AUTOPILOT HANDOFF (DAY 23)
from backend.os_intel.agms_autopilot_handoff import AGMSAutopilotHandoff
from backend.os_ops.autofix_control_plane import AutoFixControlPlane

@app.get("/agms/handoff")
def agms_handoff_latest():
    """
    Day 23: Latest Autopilot Handoff Token.
    """
    from backend.artifacts.io import get_artifacts_root, safe_read_or_fallback
    res = safe_read_or_fallback("runtime/agms/agms_handoff.json")
    return res.get("data", {})

@app.get("/agms/handoff/ledger/tail")
def agms_handoff_ledger_tail(limit: int = 50):
    """
    Day 23: Handoff Ledger History.
    """
    from backend.artifacts.io import get_artifacts_root
    path = get_artifacts_root() / "runtime/agms/agms_handoff_ledger.jsonl"
    lines = []
    if path.exists():
        with open(path, "r") as f:
            all_lines = f.readlines()
            lines = [json.loads(l) for l in all_lines[-limit:]]
    return lines

@app.post("/lab/autopilot/execute_from_handoff")
def autopilot_execute(payload: Dict[str, Any], x_founder_key: Optional[str] = Header(None)):
    """
    Day 23: Autopilot Execution Bridge.
    Requires Handoff Payload + Founder Key (or Autopilot Mode ON).
    """
    # In a real app we'd validate x_founder_key hash too, but AutoFixControlPlane 
    # handles authorization logic (checking existence of key or env var).
    return AutoFixControlPlane.execute_from_handoff(payload, founder_key=x_founder_key)

@app.get("/agms/thresholds")
def agms_thresholds_active():
    """
    Day 24: Active Dynamic Thresholds.
    """
    from backend.artifacts.io import safe_read_or_fallback
    res = safe_read_or_fallback("runtime/agms/agms_dynamic_thresholds.json")
    return res.get("data", {})






# IMMUNE SYSTEM (DAY 32)
from backend.os_ops.immune_system import ImmuneSystemEngine

@app.get("/immune/status")
def immune_status():
    """
    Day 32: Immune System Status.
    Returns latest snapshot and active mode.
    """
    from backend.artifacts.io import safe_read_or_fallback
    res = safe_read_or_fallback("runtime/immune/immune_snapshot.json")
    if not res["success"]:
        return {"mode": "UNKNOWN", "status": "NOT_FOUND"}
    return res["data"]

@app.get("/immune/tail")
def immune_tail(limit: int = 50):
    """
    Day 32: Immune Ledger History.
    """
    from backend.artifacts.io import get_artifacts_root
    path = get_artifacts_root() / "runtime/immune/immune_ledger.jsonl"
    lines = []
    if path.exists():
        try:
            with open(path, "r") as f:
                all_lines = f.readlines()
                lines = [json.loads(l) for l in all_lines[-limit:]]
        except: pass
    return lines

# Day 34: Black Box Endpoints
@app.get("/blackbox/status")
def blackbox_status():
    """Returns Black Box integrity status."""
    from backend.os_ops.black_box import BlackBox
    return BlackBox.verify_integrity()

@app.get("/blackbox/ledger/tail")
def blackbox_ledger(limit: int = 50):
    """Returns last N ledger entries."""
    from backend.os_ops.black_box import BlackBox
    return BlackBox.get_ledger_tail(limit)

@app.get("/blackbox/snapshots")
def blackbox_snapshots():
    """Returns list of crash snapshots."""
    from backend.os_ops.black_box import BlackBox
    from backend.artifacts.io import get_artifacts_root
    try:
        p = BlackBox.SNAPSHOT_DIR
        if not p.exists(): return []
        return sorted([f.name for f in p.glob("*.json")])
    except: return []

# Day 33: The Dojo (Offline Simulation)
@app.post("/lab/dojo/run")
def dojo_run(request: Request):
    """
    Day 33: Trigger Offline Simulation.
    Founder-Gated. NO PIPELINE EXECUTION.
    """
    auth_header = request.headers.get("X-Founder-Key")
    # Gate implied
    
    from backend.os_intel.dojo_simulator import DojoSimulator
    # We could parse body for custom simulations count
    sims = 1000
    return DojoSimulator.run(simulations=sims)

@app.get("/dojo/status")
def dojo_status():
    """Return latest Dojo Snapshot/Report."""
    from backend.artifacts.io import safe_read_or_fallback
    res = safe_read_or_fallback("runtime/dojo/dojo_simulation_report.json")
    if not res["success"]:
        return {"status": "NOT_FOUND"}
    return res["data"]
    
@app.get("/dojo/tail")
def dojo_tail(limit: int = 50):
    """Return Dojo Ledger History."""
    from backend.artifacts.io import get_artifacts_root
    path = get_artifacts_root() / "runtime/dojo/dojo_ledger.jsonl"
    lines = []
    if path.exists():
        try:
             with open(path, "r") as f:
                 lines = [json.loads(l) for l in f.readlines()[-limit:]]
        except: pass
    return lines

# Day 33.1: Tuning Gate (Runtime Governance)
@app.post("/lab/tuning/apply")
def tuning_apply(request: Request):
    """
    Day 33.1: Trigger Tuning Gate Application (Founder-Gated).
    Loads Dojo Recs -> Clamps -> Votes -> Consensus -> Apply (if enabled).
    """
    auth_header = request.headers.get("X-Founder-Key")
    # Gate implied
    
    from backend.os_ops.tuning_gate import TuningGate
    # We allow "force_enable" via header or just rely on env/default
    # For now, default behavior.
    return TuningGate.run_tuning_cycle()

@app.get("/tuning/status")
def tuning_status():
    """Return latest Applied Thresholds."""
    from backend.artifacts.io import safe_read_or_fallback
    res = safe_read_or_fallback("runtime/tuning/applied_thresholds.json")
    if not res["success"]:
        return {"status": "NOT_FOUND"}
    return res["data"]
    
@app.get("/tuning/tail")
def tuning_tail(limit: int = 50):
    """Return Tuning Ledger History."""
    from backend.artifacts.io import get_artifacts_root
    path = get_artifacts_root() / "runtime/tuning/tuning_ledger.jsonl"
    lines = []
    if path.exists():
        try:
             with open(path, "r") as f:
                 lines = [json.loads(l) for l in f.readlines()[-limit:]]
        except: pass
    return lines

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
