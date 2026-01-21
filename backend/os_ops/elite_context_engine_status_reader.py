import json
import os
from datetime import datetime, timezone
from typing import List, Optional
from pydantic import BaseModel
from .elite_os_reader import EliteOSReader

# Constants
PATH_RUN_MANIFEST = "outputs/run_manifest.json"
PATH_CONTEXT_MARKET_SNIPER = "outputs/context/context_market_sniper.json"
PATH_GLOBAL_RISK = "outputs/os/global_risk_state.json"
PATH_LOCK_REASON = "outputs/os/lock_reason.json" # If exists

# Freshness Thresholds (Seconds)
THRESHOLD_STALE = 900 # 15 minutes
THRESHOLD_DEGRADED = 3600 # 1 hour

class ArtifactRef(BaseModel):
    path: str
    present: bool
    as_of_utc: Optional[str] = None

class EliteContextEngineStatusSnapshot(BaseModel):
    status: str # LIVE | STALE | LOCKED | DEGRADED | UNAVAILABLE
    as_of_utc: Optional[str] = None
    age_seconds: Optional[int] = None
    reason_code: Optional[str] = None
    artifact_refs: List[ArtifactRef]

class EliteContextEngineStatusReader:
    
    def get_status(self) -> EliteContextEngineStatusSnapshot:
        refs = []
        
        # 1. Check Artifacts
        manifest = self._check_artifact(PATH_RUN_MANIFEST)
        refs.append(manifest)
        
        context = self._check_artifact(PATH_CONTEXT_MARKET_SNIPER)
        refs.append(context)
        
        risk = self._check_artifact(PATH_GLOBAL_RISK)
        refs.append(risk)
        
        # 2. Check for Locks (Iron OS interaction)
        lock_ref = self._check_artifact(PATH_LOCK_REASON)
        is_locked = False
        lock_reason = None
        if lock_ref.present:
             # Basic read
             try:
                 with open(PATH_LOCK_REASON, 'r') as f:
                     content = json.load(f)
                     # If lock reason exists and is active
                     if content.get("active", False):
                         is_locked = True
                         lock_reason = content.get("reason_code", "UNKNOWN_LOCK")
             except:
                 pass

        # 3. Determine Status
        now_utc = datetime.now(timezone.utc)
        
        # Rule: Any missing critical artifact -> UNAVAILABLE
        if not manifest.present:
            return EliteContextEngineStatusSnapshot(
                status="UNAVAILABLE",
                as_of_utc=now_utc.isoformat(),
                reason_code="MISSING_MANIFEST",
                artifact_refs=refs
            )
            
        # Determine Age from Manifest
        manifest_ts = None
        if manifest.as_of_utc:
            try:
                manifest_dt = datetime.fromisoformat(manifest.as_of_utc.replace("Z", "+00:00"))
                manifest_ts = manifest_dt
            except:
                pass
                
        age_seconds = 0
        if manifest_ts:
            age_seconds = int((now_utc - manifest_ts).total_seconds())
        
        # Rule: Locked -> LOCKED
        if is_locked:
             return EliteContextEngineStatusSnapshot(
                status="LOCKED",
                as_of_utc=manifest.as_of_utc,
                age_seconds=age_seconds,
                reason_code=lock_reason or "SYSTEM_LOCKED",
                artifact_refs=refs
            )

        # Rule: Stale vs Degraded vs Live
        if age_seconds > THRESHOLD_DEGRADED:
             return EliteContextEngineStatusSnapshot(
                status="DEGRADED",
                as_of_utc=manifest.as_of_utc,
                age_seconds=age_seconds,
                reason_code="DATA_TOO_OLD",
                artifact_refs=refs
            )
            
        if age_seconds > THRESHOLD_STALE:
             return EliteContextEngineStatusSnapshot(
                status="STALE",
                as_of_utc=manifest.as_of_utc,
                age_seconds=age_seconds,
                reason_code="FRESHNESS_DRIFT",
                artifact_refs=refs
            )
            
        if not context.present:
             return EliteContextEngineStatusSnapshot(
                status="DEGRADED",
                as_of_utc=manifest.as_of_utc,
                age_seconds=age_seconds,
                reason_code="MISSING_CONTEXT",
                artifact_refs=refs
            )

        return EliteContextEngineStatusSnapshot(
            status="LIVE",
            as_of_utc=manifest.as_of_utc,
            age_seconds=age_seconds,
            reason_code="OPERATIONAL",
            artifact_refs=refs
        )

    def _check_artifact(self, path: str) -> ArtifactRef:
        if not os.path.exists(path):
            return ArtifactRef(path=path, present=False)
            
        try:
            with open(path, 'r') as f:
                data = json.load(f)
                # Try to find a standard timestamp
                ts = data.get("as_of_utc") or data.get("timestamp_utc") or data.get("run_ts_utc")
                # Fallback to mtime if needed? strict mode prefers internal TS.
                return ArtifactRef(path=path, present=True, as_of_utc=ts)
        except:
             return ArtifactRef(path=path, present=True, as_of_utc=None)
