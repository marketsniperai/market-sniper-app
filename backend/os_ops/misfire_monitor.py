import time
import json
import os
import requests
import google.auth
from google.auth.transport.requests import Request as GoogleRequest
from datetime import datetime
from backend.artifacts.io import safe_read_or_fallback, atomic_write_json
from backend.os_ops.misfire_diagnostics import get_misfire_diagnostics

# Default threshold 26 hours (93600 seconds)
DEFAULT_THRESHOLD = 93600 

def check_misfire_status():
    """
    Checks artifact freshness and returns a misfire report dict.
    Persists the report to misfire_report.json.
    """
    # Dynamic Thresholds (Day 24)
    from backend.artifacts.io import safe_read_or_fallback, get_artifacts_root
    dyn_res = safe_read_or_fallback("runtime/agms/agms_dynamic_thresholds.json")
    threshold = DEFAULT_THRESHOLD
    
    if dyn_res["success"]:
        threshold = dyn_res["data"].get("thresholds", {}).get("misfire_threshold_seconds", DEFAULT_THRESHOLD)
    else:
        # Fallback to env var or default
        threshold_str = os.environ.get("MISFIRE_THRESHOLD_SECONDS")
        if threshold_str: threshold = int(threshold_str)

    report = {
        "timestamp_utc": datetime.utcnow().isoformat(),
        "status": "NOMINAL",
        "artifact_age_seconds": 0.0,
        "last_run_id": "UNKNOWN",
        "reason": "OK",
        "recommended_action": "NONE",
    }
    
    # --- DIAGNOSTICS ENRICHMENT (Day 62 Expansion) ---
    report["diagnostics"] = get_misfire_diagnostics()
    # -------------------------------------------------
    
    # Check run_manifest (FULL is truth)
    result = safe_read_or_fallback("full/run_manifest.json")
    if not result["success"]:
        report["status"] = "MISFIRE"
        report["reason"] = "MISSING_ARTIFACT"
        report["recommended_action"] = "RUN_PIPELINE_FULL"
        atomic_write_json("misfire_report.json", report)
        return report
        
    data = result["data"]
    report["last_run_id"] = data.get("run_id", "UNKNOWN")
    ts_str = data.get("timestamp")
    
    if not ts_str:
        report["status"] = "MISFIRE"
        report["reason"] = "INVALID_MANIFEST_TIMESTAMP"
        report["recommended_action"] = "RUN_PIPELINE_FULL"
        atomic_write_json("misfire_report.json", report)
        return report

    try:
        # Handle "Z" or other formats if needed, but assuming standard ISO from our pipeline
        if ts_str.endswith("Z"):
            ts_str = ts_str[:-1]
        
        last_run_dt = datetime.fromisoformat(ts_str)
        
        # Normalize to naive UTC if offset-aware
        if last_run_dt.tzinfo is not None:
            last_run_dt = last_run_dt.replace(tzinfo=None)
            
        now = datetime.utcnow()
        age = (now - last_run_dt).total_seconds()
        
        report["artifact_age_seconds"] = age
        
        if age > threshold:
             report["status"] = "MISFIRE"
             report["reason"] = "STALE_ARTIFACTS"
             report["recommended_action"] = "RUN_PIPELINE_FULL"
             
    except Exception as e:
        report["status"] = "MISFIRE"
        report["reason"] = f"TIMESTAMP_PARSE_ERROR: {str(e)}"
        report["recommended_action"] = "CHECK_LOGS"

    atomic_write_json("misfire_report.json", report)
    return report

def trigger_autoheal():
    """
    Triggers the Cloud Run Job using default credentials.
    """
    # These env vars must be set in the service
    project = os.environ.get("PROJECT_ID", "marketsniper-intel-osr-9953") 
    region = os.environ.get("REGION", "us-central1")
    job = os.environ.get("JOB_NAME", "market-sniper-pipeline")
    
    # API Endpoint
    url = f"https://{region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/{project}/jobs/{job}:run"
    
    try:
        credentials, project_id = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
        credentials.refresh(GoogleRequest())
        token = credentials.token
        
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        # Pass -m backend.pipeline_controller --mode FULL to the job (Python entrypoint)
        # Fix for Day 14.01: Explicitly pass module args as the command is 'python'
        args_override = ["-m", "backend.pipeline_controller", "--mode", "FULL"]
        
        # Evidence Logging (Day 14.01 Requirement)
        evidence = {
            "timestamp_utc": datetime.utcnow().isoformat(),
            "job_name": job,
            "args_sent": args_override,
            "action": "AUTOHEAL_INVOCATION",
            "trigger_url": url
        }
        try:
             # Try writing to runtime/ subdir if implied by structure, else verify folder exists or fail gracefully
             # For safety/simplicity in this fix, we try standard write via atomic_write_json
             # Note: 'runtime' folder in bucket must exist.
             atomic_write_json("day_14_01_autoheal_invocation.json", evidence)
        except Exception as e:
             print(f"Evidence log failed: {e}")

        payload = {
            "overrides": {
                "container_overrides": [
                    {
                        "args": args_override
                    }
                ]
            }
        }
        resp = requests.post(url, headers=headers, json=payload)
        resp.raise_for_status()
        
        result_data = resp.json()
        
        # Update evidence with result
        evidence["result"] = "TRIGGERED"
        evidence["provider_response"] = result_data
        try:
            atomic_write_json("day_14_01_autoheal_invocation.json", evidence)
        except:
            pass
            
        return {"result": "TRIGGERED", "details": result_data}
        
    except Exception as e:
        print(f"Autoheal Trigger Failed: {e}")
        return {"result": "FAILED", "error": str(e)}

def update_nominal_on_success(run_id: str):
    """
    Called by pipeline to force-update misfire report to NOMINAL
    after a successful run, resetting age to 0 essentially.
    """
    report = {
        "timestamp_utc": datetime.utcnow().isoformat(),
        "status": "NOMINAL",
        "artifact_age_seconds": 0.0,
        "last_run_id": run_id,
        "reason": "PIPELINE_SUCCESS",
        "recommended_action": "NONE",
        "diagnostics": get_misfire_diagnostics()
    }
    atomic_write_json("misfire_report.json", report)
