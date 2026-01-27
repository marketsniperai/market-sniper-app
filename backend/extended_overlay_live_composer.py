import json
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List

from backend.artifacts.io import get_artifacts_root, safe_read_or_fallback, atomic_write_json

# ARTIFACT PATHS
SENTINEL_ARTIFACT_PATH = "engine/sector_sentinel_rt.json"
OVERLAY_ARTIFACT_PATH = "engine/extended_overlay_live.json"

# CANON CONSTANTS
MAX_AGE_SECONDS = 300  # 5 Minutes (Matches Pulse/Light)

def generate_overlay_live() -> Dict[str, Any]:
    """
    D40.04: Extended Overlay LIVE Composer.
    Source: SECTOR_SENTINEL (Strict).
    Status: LIVE | PARTIAL | STALE | N_A
    """
    
    # 1. READ SOURCE
    sentinel_res = safe_read_or_fallback(SENTINEL_ARTIFACT_PATH)
    
    # 2. DEFAULT STATE (N_A)
    status = "N_A"
    summary_lines = []
    sectors_mapped = []
    diagnostics = {
        "provider_result": "MISSING",
        "fallback_reason": "SENTINEL_MISSING",
        "input_artifact_path": SENTINEL_ARTIFACT_PATH,
        "input_as_of_utc": None,
        "missing_sectors": []
    }
    
    current_time = datetime.utcnow().isoformat()
    age_seconds = 0
    
    # 3. EVALUATE SOURCE
    if sentinel_res["success"]:
        data = sentinel_res["data"]
        diagnostics["provider_result"] = "OK"
        diagnostics["fallback_reason"] = "NONE"
        
        # Check Timestamp
        as_of_str = data.get("as_of_utc")
        if as_of_str:
            diagnostics["input_as_of_utc"] = as_of_str
            try:
                as_of_dt = datetime.fromisoformat(as_of_str)
                now_dt = datetime.utcnow()
                age_seconds = int((now_dt - as_of_dt).total_seconds())
                
                # Check Stale
                if age_seconds > MAX_AGE_SECONDS:
                    status = "STALE"
                    diagnostics["fallback_reason"] = "SENTINEL_STALE"
                else:
                    status = "LIVE"
                    
            except:
                status = "ERROR"
                diagnostics["fallback_reason"] = "TIMESTAMP_PARSE_ERROR"
        else:
            status = "N_A"
            diagnostics["fallback_reason"] = "SENTINEL_TIMESTAMP_MISSING"
            
        # Map Sectors (If valid so far)
        if status in ["LIVE", "STALE", "PARTIAL"]:
            # Check Sentinels Sectors
            sentinel_sectors = data.get("sectors", [])
            mapped_count = 0
            
            # We expect 11 sectors. If less, PARTIAL.
            # D40.04 Contract: Map strictly.
            
            for s in sentinel_sectors:
                # Minimal mapping
                sectors_mapped.append({
                    "sector": s.get("sector_id", "UNKNOWN"),
                    "state": s.get("status", "UNKNOWN"), # ACTIVE / STALE etc
                    "pressure": s.get("pressure", "UNKNOWN"),
                    "dispersion": s.get("dispersion", "UNKNOWN"),
                    "as_of_utc": s.get("as_of_utc", current_time)
                })
                mapped_count += 1
                
            if mapped_count < 11 and status == "LIVE":
                 status = "PARTIAL"
                 diagnostics["fallback_reason"] = "SENTINEL_PARTIAL_SECTORS"
                 
            # Generate Summary
            # Deterministic Summary based on counts
            risk_on = sum(1 for s in sectors_mapped if s.get("pressure") == "UP")
            risk_off = sum(1 for s in sectors_mapped if s.get("pressure") == "DOWN")
            mixed = sum(1 for s in sectors_mapped if s.get("pressure") == "MIXED")
            
            summary_lines.append(f"Sector Sentinel: {mapped_count}/11 Active")
            summary_lines.append(f"Pressure: {risk_on} Up, {risk_off} Down, {mixed} Mixed")
            
            if status == "STALE":
                summary_lines.insert(0, f"[WARNING] Data Stale ({age_seconds}s old)")
            elif status == "PARTIAL":
                summary_lines.insert(0, "[WARNING] Partial Sector Coverage")

    else:
        # Source Missing Case
        summary_lines = ["Sector Sentinel Unavailable", "Overlay: N/A"]
        
    # 4. CONSTRUCT ARTIFACT
    artifact = {
        "version": "1.0",
        "as_of_utc": current_time,
        "status": status,
        "source": "SECTOR_SENTINEL",
        "age_seconds": age_seconds,
        "summary_lines": summary_lines,
        "sectors": sectors_mapped,
        "diagnostics": diagnostics
    }
    
    # 5. ATOMIC WRITE
    try:
        atomic_write_json(OVERLAY_ARTIFACT_PATH, artifact)
    except Exception as e:
        # Fallback in memory return if write fails (unlikely)
        artifact["status"] = "ERROR"
        artifact["diagnostics"]["write_error"] = str(e)
        
    return artifact
    
if __name__ == "__main__":
    # Test Run
    print(json.dumps(generate_overlay_live(), indent=2))
