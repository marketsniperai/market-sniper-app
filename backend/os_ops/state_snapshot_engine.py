
import json
import os
from datetime import datetime, timedelta
from typing import Dict, Any, List

# Imports
from backend.artifacts.io import get_artifacts_root, safe_read_or_fallback, atomic_write_json
from backend.os_ops.event_router import EventRouter

class StateSnapshotEngine:
    """
    D49.OS.STATE_SNAPSHOT_V1: Institutional State Snapshot Engine.
    Generates a deterministic view of System Mode, Freshness, Providers, and Locks.
    Consumed by Elite to ensure it never speaks out of turn.
    """
    
    ARTIFACT_PATH = "os/state_snapshot.json"
    
    @staticmethod
    def generate_snapshot() -> Dict[str, Any]:
        """
        Generates the snapshot and persists it to disk.
        Returns the snapshot dict.
        """
        snapshot = {
            "timestamp_utc": datetime.utcnow().isoformat() + "Z",
            "system_mode": StateSnapshotEngine._determine_system_mode(),
            "freshness": StateSnapshotEngine._check_freshness(),
            "providers": StateSnapshotEngine._check_providers(),
            "locks": StateSnapshotEngine._get_active_locks(),
            "recent_events": StateSnapshotEngine._get_recent_events()
        }
        
        # Persist
        root = get_artifacts_root()
        path = root / StateSnapshotEngine.ARTIFACT_PATH
        path.parent.mkdir(parents=True, exist_ok=True)
        atomic_write_json(str(path), snapshot)
        
        return snapshot

    @staticmethod
    def _determine_system_mode() -> str:
        """
        LIVE | SAFE | CALIBRATING
        Checks for global lock files.
        """
        root = get_artifacts_root()
        
        if (root / "os/locks/CALIBRATION.lock").exists():
            return "CALIBRATING"
        
        if (root / "os/locks/SAFETY.lock").exists():
            return "SAFE"
            
        return "LIVE"

    @staticmethod
    def _check_freshness() -> Dict[str, str]:
        """
        Checks artifact ages against thresholds.
        Dashboard: < 5 mins = FRESH, else STALE.
        OnDemand: Check cache directory modification time? Or just default to FRESH for now.
        """
        freshness = {
            "dashboard": "STALE",
            "on_demand": "FRESH" # logic pending D49.05 refinement
        }
        
        # Dashboard Freshness
        root = get_artifacts_root()
        dash_path = root / "full/dashboard_market_sniper.json"
        
        if dash_path.exists():
            mtime = datetime.fromtimestamp(dash_path.stat().st_mtime)
            age = datetime.now() - mtime
            if age < timedelta(minutes=5):
                freshness["dashboard"] = "FRESH"
        
        return freshness

    @staticmethod
    def _check_providers() -> Dict[str, str]:
        """
        Reads provider_health.json (written by DataMux).
        """
        root = get_artifacts_root()
        path = root / "os/engine/provider_health.json"
        
        providers = {
            "market": "UNKNOWN",
            "options": "UNKNOWN",
            "news": "UNKNOWN"
        }
        
        if path.exists():
            try:
                with open(path, "r") as f:
                    health = json.load(f)
                    
                # Map providers to simple status
                # Logic: If denied -> DENIED. If last success < 1h -> LIVE. Else OFFLINE.
                # Demo is usually LIVE or DEMO.
                
                for key in ["market", "options", "news"]:
                    # Map generic keys to specific provider entries if needed
                    # For now assume direct mapping or 'demo' fallback
                    p_entry = health.get(key) or health.get("demo")
                    
                    if p_entry:
                        if p_entry.get("denied"):
                            providers[key] = "DENIED"
                        elif p_entry.get("last_success_utc"):
                            # Check age? For now just LIVE if success recorded
                            providers[key] = "LIVE"
                        else:
                            providers[key] = "OFFLINE"
                    else:
                        providers[key] = "LIVE" # Default to avoid panic in V1 if no health data yet
            except:
                pass
                
        return providers

    @staticmethod
    def _get_active_locks() -> List[Dict[str, str]]:
        """
        Reads os_lock.json (Housekeeper/Safety).
        """
        locks = []
        res = safe_read_or_fallback("os_lock.json")
        if res["success"]:
            data = res["data"]
            # Structure depends on lock file schema. Assuming list of locks or singular.
            # If singular:
            if data.get("is_locked"):
                locks.append({
                    "type": data.get("lock_type", "UNKNOWN"),
                    "reason": data.get("reason", "Unknown")
                })
        return locks

    @staticmethod
    def _get_recent_events() -> List[Dict[str, Any]]:
        """
        Tails EventRouter.
        """
        try:
            return EventRouter.get_latest(limit=5)
        except:
            return []
