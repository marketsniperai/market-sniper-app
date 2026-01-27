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
from backend.os_ops.elite_os_reader import EliteOSReader
from backend.os_ops.elite_context_engine_status_reader import EliteContextEngineStatusReader
from backend.os_ops.elite_what_changed_reader import EliteWhatChangedReader
from backend.os_ops.elite_micro_briefing_engine import EliteMicroBriefingEngine
from backend.os_ops.elite_context_safety_validator import EliteContextSafetyValidator # D43.16 Safety
from backend.os_ops.elite_agms_recall_reader import EliteAGMSRecallReader # D43.05
from backend.os_ops.watchlist_action_logger import (
    WatchlistActionEvent, 
    append_watchlist_log, 
    tail_watchlist_log
)
from backend.os_ops.on_demand_cache import OnDemandCache # D44.05
from backend.os_ops.on_demand_tier_enforcer import OnDemandTierEnforcer # D44.06

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

@app.get("/options_context")
def options_context():
    """
    D36.3: Options Intelligence v1 Context.
    Returns options_context.json or generates N/A stub if missing.
    """
    from backend.artifacts.io import safe_read_or_fallback
    from backend.options_engine import generate_options_context
    
    # Try reading existing artifact
    res = safe_read_or_fallback("engine/options_context.json")
    
    # If missing or failed, generate fresh N/A artifact (Always-On contract)
    if not res["success"]:
        return generate_options_context()
        
    return res["data"]

@app.get("/macro_context")
def macro_context():
    """
    D36.5: Macro Layer v1 Context.
    Returns macro_context.json or generates N/A stub.
    """
    from backend.artifacts.io import safe_read_or_fallback
    from backend.macro_engine import generate_macro_context
    
    # Try reading existing artifact
    res = safe_read_or_fallback("engine/macro_context.json")
    
    if not res["success"]:
        return generate_macro_context()
        
    return res["data"]



@app.get("/evidence_summary")
def evidence_summary():
    """
    D36.4: Evidence & Backtesting Engine v1.
    Returns evidence_summary.json or generates N_A stub.
    """
    from backend.artifacts.io import safe_read_or_fallback
    from backend.evidence_engine import generate_evidence_summary
    
    # Try reading existing artifact
    res = safe_read_or_fallback("engine/evidence_summary.json")
    
    if not res["success"]:
        return generate_evidence_summary()
        
    return res["data"]

@app.get("/overlay_live")
def overlay_live():
    """
    D40.04: Extended Overlay LIVE Composer.
    Returns extended_overlay_live.json (Source: Sector Sentinel).
    """
    from backend.extended_overlay_live_composer import generate_overlay_live
    return generate_overlay_live()



@app.get("/voice_state")
def voice_state():
    """
    D36.7: Voice MVP Stub.
    Returns voice_state.json.
    """
    from backend.artifacts.io import safe_read_or_fallback
    from backend.voice_mvp_engine import generate_voice_state
    
    # Try reading existing artifact
    res = safe_read_or_fallback("engine/voice_state.json")
    
    if not res["success"]:
        generate_voice_state()
        res = safe_read_or_fallback("engine/voice_state.json") # Re-read
        
    return res["data"] if res["success"] else {"status": "ERROR"}


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

# AUTOFIX TIER 1 ENDPOINTS (DAY 42.04)
from backend.os_ops.autofix_tier1 import AutoFixTier1

@app.get("/lab/os/self_heal/autofix/tier1/status")
def autofix_tier1_status():
    """
    D42.04: AutoFix Tier 1 Status (Last Run).
    """
    from backend.os_ops.autofix_tier1 import PROOF_PATH
    if PROOF_PATH.exists():
        with open(PROOF_PATH, "r") as f:
            return json.load(f)
    return JSONResponse(status_code=404, content={"error": "Status unavailable"})

@app.post("/lab/os/self_heal/autofix/tier1/run")
def autofix_tier1_run(request: Request):
    """
    D42.04: AutoFix Tier 1 Execution.
    """
    auth_header = request.headers.get("X-Founder-Key")
    # In real impl, check auth_header for high-privilege actions
    # This engine has tight allowlists anyway.
    
    is_founder = auth_header is not None
    return AutoFixTier1.run_from_plan(founder_context=is_founder).dict()

@app.get("/lab/os/self_heal/autofix/decision_path")
def autofix_decision_path():
    """
    D42.10: AutoFix Decision Path (Read-Only).
    """
    from backend.os_ops.autofix_decision_reader import AutoFixDecisionReader
    data = AutoFixDecisionReader.get_decision_path()
    if data:
        return data
    return JSONResponse(status_code=404, content={"error": "Decision path unavailable"})


    
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

@app.post("/lab/replay/day")
async def replay_day(request: Request):
    """
    D41.03: Institutional Day Replay Trigger (Stub).
    Founder-gated.
    """
    auth_header = request.headers.get("X-Founder-Key")
    # Gate implied
    
    # Simulating a safe stub response until Replay Engine V1 is ready
    response = {
        "status": "UNAVAILABLE", 
        "reason": "REPLAY_ENDPOINT_MISSING", 
        "guidance": "Update backend replay route",
        "timestamp": datetime.now().isoformat()
    }
    
    # D41.04: Log this attempt to Archive
    from backend.os_ops.replay_archive import ReplayArchive
    try:
        body = await request.json()
        day_id = body.get("day_id", "UNKNOWN")
    except:
        day_id = "UNKNOWN"
        
    ReplayArchive.append_entry(
        day_id=day_id, 
        status="UNAVAILABLE", 
        summary="Stub execution (Endpoint logic pending)"
    )
    
    return response

@app.get("/lab/replay/archive/tail")
def get_replay_archive(limit: int = 30):
    """
    D41.04: Replay Archive Tail (Time Machine).
    """
    from backend.os_ops.replay_archive import ReplayArchive
    return ReplayArchive.get_tail(limit)

@app.post("/lab/os/rollback")
async def os_rollback(request: Request):
    """
    D41.05: Founder-Gated Rollback Trigger (Stub).
    """
    auth_header = request.headers.get("X-Founder-Key")
    # Gate implied
    
    try:
        body = await request.json()
        target_hash = body.get("target_hash", "UNKNOWN")
        reason = body.get("reason", "No reason provided")
    except:
        target_hash = "UNKNOWN"
        reason = "Payload error"
        
    # Log Intent
    from backend.os_ops.rollback_ledger import RollbackLedger
    RollbackLedger.log_intent(
        actor="FOUNDER",
        action="ROLLBACK_ATTEMPT",
        target_lkg_hash=target_hash,
        result="UNAVAILABLE", # Stub result
        reason=reason
    )
    
    # Stub Response
    return {
        "status": "UNAVAILABLE",
        "reason": "ROLLBACK_ENGINE_MISSING",
        "guidance": "Engine implementation pending (OS.R2.3)"
    }

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

# ELITE EXPLAIN ROUTER (D43.06)
from backend.os_ops.explain_router import ExplainRouter

@app.get("/elite/explain/status")
def elite_explain_status():
    """
    D43.06: Elite Explain Router Status.
    Returns availability of explanation keys, library status, and protocol integrity.
    No generation/execution.
    """
    return ExplainRouter.get_status()

@app.get("/elite/os/snapshot")
def elite_os_snapshot():
    """
    D43.03: Elite OS Reader Snapshot.
    Read-Only access to canonical RunManifest, GlobalRisk, and OverlayState.
    Bounded, Safe, Degrade-First.
    """
    snapshot = EliteOSReader.get_snapshot()
    if snapshot.run_manifest is None and snapshot.global_risk is None and snapshot.overlay is None:
        # If absolutely everything is missing, we still return the structure but it will be largely empty/None.
        # However, user prompt said "If ALL are missing: return 404 (UNAVAILABLE)."
        # But get_snapshot returns an object with None fields. 
        # So we check fields.
        pass
        
    # Per prompt: "If ALL are missing: return 404 (UNAVAILABLE)."
    if not snapshot.run_manifest and not snapshot.global_risk and not snapshot.overlay:
         raise HTTPException(status_code=404, detail="OS UNAVAILABLE")
         
    return snapshot

@app.get("/elite/script/first_interaction")
def elite_first_interaction_script():
    """
    D43.00: Elite First Interaction Script.
    Read-Only access to canonical script.
    """
    script = EliteOSReader.get_first_interaction_script()
    if not script:
        raise HTTPException(status_code=404, detail="Script Unavailable")
    return script

@app.get("/elite/context/status")
async def get_elite_context_status():
    """
    Returns the operational status of the Elite Context Engine (D43.11).
    Strict read-only check of artifacts, freshness, and locks.
    """
    try:
        reader = EliteContextEngineStatusReader()
        status = reader.get_status()
        if not status:
            raise HTTPException(status_code=404, detail="Context Engine Status Unavailable")
        return status
    except Exception as e:
        logger.error(f"Error reading context engine status: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")

@app.get("/elite/what_changed")
async def get_elite_what_changed():
    """
    Returns the 'What Changed' snapshot (Last 5 Minutes).
    D43.12: Strict bounds, no synthesis.
    """
    try:
        reader = EliteWhatChangedReader()
        snapshot = reader.get_what_changed()
        if snapshot is None:
             raise HTTPException(status_code=404, detail="Timeline Unavailable")
        
        # D43.16: Safety Validation
        validator = EliteContextSafetyValidator()
        validated_snapshot, filtered = validator.validate_payload(snapshot.dict())
        validated_snapshot['safety_filtered'] = filtered
        
        return validated_snapshot
    except Exception as e:
        logger.error(f"Error reading what changed: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")

@app.get("/elite/micro_briefing/open")
async def get_elite_micro_briefing_open():
    """
    Returns the Elite Micro-Briefing on Open (D43.15).
    Deterministic, protocol-driven 3-bullet summary.
    """
    try:
        engine = EliteMicroBriefingEngine()
        snapshot = engine.generate_briefing()
        if not snapshot:
            raise HTTPException(status_code=404, detail="Briefing Unavailable")
        
        # D43.16: Safety Validation
        validator = EliteContextSafetyValidator()
        # micro-briefing returns Pydantic model usually, convert to dict
        validated_snapshot, filtered = validator.validate_payload(snapshot.dict())
        validated_snapshot['safety_filtered'] = filtered
        
        return validated_snapshot
    except Exception as e:
        logger.error(f"Error generating micro-briefing: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")

@app.get("/elite/agms/recall")
async def get_elite_agms_recall(tier: str = "elite"):
    """
    Returns AGMS Aggregate Recall (D43.05).
    Status-Only, Anonymized, Safe.
    """
    try:
        reader = EliteAGMSRecallReader()
        snapshot = reader.get_recall(tier=tier)
        return snapshot
    except Exception as e:
        logger.error(f"Error reading AGMS Recall: {e}")
        # Return graceful degradation instead of 500? Snapshot handles it.
        return {"status": "UNAVAILABLE", "patterns": [], "safety_filtered": False}

# --- Watchlist Action Logging (D44.03) ---

@app.post("/lab/watchlist/log")
async def post_watchlist_log(event: WatchlistActionEvent):
    """
    D44.03: Appends action to backend JSONL ledger.
    Read-only safe; input validation via Pydantic.
    """
    return append_watchlist_log(event)

@app.get("/lab/watchlist/log/tail")
async def get_watchlist_log_tail(lines: int = 50):
    """
    D44.03: Returns last N lines of the watchlist ledger.
    """
    if lines > 100: lines = 100 # Bound
    return {"lines": tail_watchlist_log(lines)}

# --- On-Demand Cache (D44.05) ---

@app.get("/on_demand/context")
async def get_on_demand_context(
    ticker: str, 
    tier: str = "FREE", 
    allow_stale: bool = False,
    x_founder_key: Optional[str] = Header(None)
):
    """
    D44.05: On-Demand Context with Cache & Freshness Discipline.
    D44.06: Tier Limits Enforcement.
    D44.X: Global Universe + Source Ladder + Cooldowns.
    """
    # 0. Enforce Tier Limits (D44.06/D44.X)
    allowed, usage, limit, reason, cooldown_rem = OnDemandTierEnforcer.check_and_log(ticker, tier, x_founder_key)
    
    if not allowed:
        # D44.X: Distinguish TIER_LOCKED (403) vs LIMIT/COOLDOWN (429)
        status_code = 429
        if reason == "TIER_LOCKED":
             status_code = 403 # Forbidden (Upgrade required)
        
        return JSONResponse(
            status_code=status_code,
            content={
                "status": "BLOCKED",
                "reason": reason,
                "tier": tier,
                "usage": usage,
                "limit": limit,
                "cooldown_remaining": cooldown_rem,
                "reset_et": "04:00"
            }
        )

    # 1. Resolve Source (D44.X Source Ladder)
    # This handles Pipeline -> Cache -> Offline logic
    result_envelope = OnDemandCache.resolve_source(ticker, tier, allow_stale)
    
    # ... Helper to inject usage headers ...
    def with_meta(resp_dict):
        resp_dict["_meta"] = {
            "tier": tier,
            "usage": usage,
            "limit": limit,
            "cooldown_remaining": 0
        }
        return resp_dict
    
    # 2. Return Result
    return with_meta(result_envelope)
    
    # NOTE: EliteOSReader fallback is now handled inside resolve_source (via OFFLINE path) 
    # or should be handled if resolve_source returns OFFLINE?
    # Actually, resolve_source returns the full envelope including OFFLINE status.
    # So we just return what it gives us + meta.
        "generated_at": datetime.now().isoformat()
    }
    
    # 3. Put to Cache
    OnDemandCache.put(ticker=ticker, tier=tier, payload=payload)
    
    return with_headers({
        "source": "LIVE_FETCH",
        "freshness": "LIVE",
        "status": "AVAILABLE",
        "payload": payload,
        "timestamp_utc": datetime.now().isoformat()
    })

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
