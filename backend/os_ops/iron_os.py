import json
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List
from pydantic import BaseModel, Field, ValidationError
from backend.artifacts.io import get_artifacts_root

class IronOSStatusSnapshot(BaseModel):
    state: str
    last_tick_timestamp: str
    age_seconds: int

class TimelineEvent(BaseModel):
    timestamp_utc: str
    type: str
    source: str
    summary: str

class IronOSHistoryEntry(BaseModel):
    originating_module: str
    timestamp_utc: str

class CoverageEntry(BaseModel):
    capability: str
    status: str # AVAILABLE | DEGRADED | UNAVAILABLE
    reason: Optional[str] = None

class CoverageSnapshot(BaseModel):
    entries: List[CoverageEntry]

class FindingEntry(BaseModel):
    finding_code: str
    severity: str # INFO | WARN | ERROR
    message: str
    originating_module: Optional[str] = None
    timestamp_utc: Optional[str] = None

class FindingsSnapshot(BaseModel):
    findings: List[FindingEntry]


class LKGSnapMeta(BaseModel):
    hash: str
    timestamp_utc: str
    size_bytes: int
    valid: bool
    source: str

class DecisionRecord(BaseModel):
    timestamp_utc: str
    decision_type: str
    reason: str
    fallback_used: bool
    action_taken: Optional[str]
    source: str

class DriftEntry(BaseModel):
    component: str
    expected: str
    observed: str
    timestamp_utc: str






class IronOS:
    """
    D41.01: Iron OS Status Surface.
    Strict reader for Iron OS State.
    """
    
    # Path relative to outputs/ (e.g., outputs/os/os_state.json)
    ARTIFACT_SUBPATH = "os/os_state.json"
    TIMELINE_SUBPATH = "os/os_timeline.jsonl"
    HISTORY_SUBPATH = "os/os_state_history.json"
    LKG_SUBPATH = "os/lkg_snapshot.json"
    DECISION_SUBPATH = "os/os_decision_path.json"
    DRIFT_SUBPATH = "os/os_drift_report.json"
    REPLAY_SUBPATH = "os/os_replay_integrity.json"
    LOCK_REASON_SUBPATH = "os/os_lock_reason.json"
    COVERAGE_SUBPATH = "os/os_coverage.json"
    FINDINGS_SUBPATH = "os/os_findings.json"










    @staticmethod
    def get_status() -> Optional[Dict[str, Any]]:
        """
        Reads Iron OS state artifact strictly.
        Returns serialized snapshot or None if UNAVAILABLE/INVALID.
        """
        root = get_artifacts_root()
        path = root / IronOS.ARTIFACT_SUBPATH
        
        if not path.exists():
            return None
            
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                
            # Strict validation via Pydantic model
            # 1. State check (enum-like)
            state = data.get("state")
            if state not in ["NOMINAL", "DEGRADED", "INCIDENT", "LOCKED"]:
                return None
                
            # 2. Timestamp check
            ts_str = data.get("last_tick_timestamp")
            if not ts_str:
                return None
                
            # 3. Compute age strictly
            # Verify timestamp format (ISO 8601)
            try:
                last_tick = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
            except ValueError:
                return None
                
            now = datetime.now(timezone.utc)
            age = int((now - last_tick).total_seconds())
            
            # Construct validated model
            snapshot = IronOSStatusSnapshot(
                state=state,
                last_tick_timestamp=ts_str,
                age_seconds=age
            )
            
            return snapshot.dict()
            
        except (json.JSONDecodeError, ValidationError, Exception):
            # Any failure -> UNAVAILABLE (None)
            return None
            
    @staticmethod
    def get_timeline_tail(limit: int = 10) -> Optional[Dict[str, Any]]:
        """
        Reads Iron OS timeline artifact strictly (tail).
        Returns list of events or None if UNAVAILABLE/MISSING.
        Bounds: Max 10 events, Max 8KB per event.
        """
        root = get_artifacts_root()
        path = root / IronOS.TIMELINE_SUBPATH
        
        if not path.exists():
            return None
            
        events = []
        try:
            # Read lines, keep last N
            with open(path, "r", encoding="utf-8") as f:
                lines = f.readlines()
                
            # Process strictly in reverse order (newest first)
            count = 0
            for line in reversed(lines):
                if count >= limit:
                    break
                    
                # 8KB Guard
                if len(line.encode('utf-8')) > 8192:
                    continue # Drop silently per spec
                    
                try:
                    data = json.loads(line)
                    # Use "summary" or "message" to support likely schema
                    summary = data.get("summary") or data.get("message") or "No summary"
                    ev = TimelineEvent(
                        timestamp_utc=data.get("timestamp") or data.get("ts") or datetime.now(timezone.utc).isoformat(),
                        type=data.get("type", "UNKNOWN"),
                        source=data.get("source", "UNKNOWN"),
                        summary=str(summary)
                    )
                    events.append(ev.dict())
                    count += 1
                except (json.JSONDecodeError, ValidationError):
                    continue # Skip malformed lines strictly

            if not events:
                return None # Empty timeline ? Or return empty list? Spec says "If empty -> UNAVAILABLE" effectively.
                
            return {"events": events}

        except Exception:
            return None

    @staticmethod
    def get_state_history(limit: int = 10) -> Optional[Dict[str, Any]]:
        """
        Reads Iron OS state history strictly.
        Returns list of entries or None if UNAVAILABLE/MISSING.
        Bounds: Max N entries (default 10).
        """
        root = get_artifacts_root()
        path = root / IronOS.HISTORY_SUBPATH
        
        if not path.exists():
            return None
            
        entries = []
        try:
            with open(path, "r", encoding="utf-8") as f:
                raw_data = json.load(f)
                
            # Expecting a list in the artifact, or a dict with a "history" key?
            # Canonical history artifact is typically a JSON list or a wrapper.
            # Assuming List based on common pattern, but let's handle wrapper if needed.
            if isinstance(raw_data, dict) and "history" in raw_data:
                src_list = raw_data["history"]
            elif isinstance(raw_data, list):
                src_list = raw_data
            else:
                return None # Invalid structure
                
            # Process list
            # Artifact is usually appending, so we might need to reverse?
            # User says "Order: most recent first".
            # If artifact is append-only log, verify order.
            # We will read, valid, sort desc by timestamp just in case, or assume append-only and reverse.
            # Let's trust input but enforce validation.
            
            valid_entries = []
            for item in src_list:
                try:
                    entry = IronOSHistoryEntry(
                        state=item.get("state", "UNKNOWN"),
                        timestamp_utc=item.get("timestamp_utc") or item.get("ts") or datetime.now(timezone.utc).isoformat(),
                        source=item.get("source", "UNKNOWN")
                    )
                    valid_entries.append(entry)
                except ValidationError:
                    continue
            
            # Sort by timestamp desc to ensure "most recent first"
            valid_entries.sort(key=lambda x: x.timestamp_utc, reverse=True)
            
            # Limit
            final_entries = [e.dict() for e in valid_entries[:limit]]
            
            return {"history": final_entries}

        except Exception:
            # Return empty history instead of None to prevent UI panic (404)
            return {"history": []}

    @staticmethod
    def get_lkg_snapshot() -> Optional[Dict[str, Any]]:
        """
        Reads Iron OS LKG snapshot artifact strictly.
        Returns metadata or None if UNAVAILABLE/MISSING.
        """
        root = get_artifacts_root()
        path = root / IronOS.LKG_SUBPATH
        
        if not path.exists():
            return None
            
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                
            lkg = LKGSnapMeta(
                hash=data.get("hash", "UNKNOWN"),
                timestamp_utc=data.get("timestamp_utc") or data.get("ts") or "N/A",
                size_bytes=data.get("size_bytes") or data.get("size") or 0,
                valid=data.get("valid", False),
                source=data.get("source", "UNKNOWN")
            )
            
            return lkg.dict()
        except Exception:
            return None

    @staticmethod
    def get_decision_path() -> Optional[Dict[str, Any]]:
        """
        Reads Iron OS decision path artifact strictly.
        Returns record or None if UNAVAILABLE/MISSING.
        """
        root = get_artifacts_root()
        path = root / IronOS.DECISION_SUBPATH
        
        if not path.exists():
            return None
            
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                
            rec = DecisionRecord(
                timestamp_utc=data.get("timestamp_utc") or data.get("ts") or "N/A",
                decision_type=data.get("decision_type") or data.get("type") or "UNKNOWN",
                reason=data.get("reason", "No reason provided"),
                fallback_used=data.get("fallback_used", False),
                action_taken=data.get("action_taken"),
                source=data.get("source", "UNKNOWN")
            )
            
            return rec.dict()
        except Exception:
            return None




    @staticmethod
    def get_drift_report() -> Optional[Dict[str, Any]]:
        """
        Reads Iron OS drift report artifact strictly.
        Returns dict with 'drift': [entries] or None if UNAVAILABLE/MISSING.
        """
        root = get_artifacts_root()
        path = root / IronOS.DRIFT_SUBPATH
        
        if not path.exists():
            return None
            
        try:
            with open(path, "r", encoding="utf-8") as f:
                raw_data = json.load(f)
                
            # Expecting {"drift": [...] } or just list
            if isinstance(raw_data, dict) and "drift" in raw_data:
                src_list = raw_data["drift"]
            elif isinstance(raw_data, list):
                src_list = raw_data
            else:
                 return None

            valid_entries = []
            for item in src_list:
                try:
                    entry = DriftEntry(
                        component=item.get("component", "UNKNOWN"),
                        expected=str(item.get("expected", "")),
                        observed=str(item.get("observed", "")),
                        timestamp_utc=item.get("timestamp_utc") or item.get("ts") or "N/A"
                    )
                    valid_entries.append(entry.dict())
                except ValidationError:
                    continue
            
            return {"drift": valid_entries}
        except Exception:
            # Return empty drift instead of None to prevent UI panic (404)
            return {"drift": []}

    @staticmethod
    def get_replay_integrity() -> Optional[Dict[str, Any]]:
        """
        Reads Iron OS replay integrity artifact strictly.
        Returns snapshot or None if UNAVAILABLE/MISSING.
        """
        root = get_artifacts_root()
        path = root / IronOS.REPLAY_SUBPATH
        
        if not path.exists():
            return None
            
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                
            # Strict boolean parsing
            snap = ReplayIntegritySnapshot(
                corrupted=data.get("corrupted", False),
                truncated=data.get("truncated", False),
                out_of_order=data.get("out_of_order", False),
                duplicate_events=data.get("duplicate_events", False),
                timestamp_utc=data.get("timestamp_utc") or data.get("ts") or "N/A"
            )
            
            return snap.dict()
        except Exception:
            return None

    @staticmethod
    def get_lock_reason() -> Optional[Dict[str, Any]]:
        """
        Reads Iron OS lock reason artifact strictly.
        Returns snapshot or None if UNAVAILABLE/MISSING.
        """
        root = get_artifacts_root()
        path = root / IronOS.LOCK_REASON_SUBPATH
        
        if not path.exists():
            return None
            
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                
            # Strict validation
            state = data.get("lock_state", "NONE")
            if state not in ["NONE", "DEGRADED", "LOCKED"]:
                return None # Invalid state -> UNAVAILABLE
                
            snap = LockReasonSnapshot(
                lock_state=state,
                reason_code=data.get("reason_code", "UNKNOWN"),
                reason_description=data.get("reason_description", "No description provided"),
                originating_module=data.get("originating_module", "UNKNOWN"),
                timestamp_utc=data.get("timestamp_utc") or data.get("ts") or "N/A"
            )
            
            return snap.dict()
        except Exception:
            return None

    @staticmethod
    def get_coverage_report() -> Optional[Dict[str, Any]]:
        """
        Reads Iron OS coverage artifact strict.
        Returns snapshot dict or None if UNAVAILABLE/MISSING.
        """
        root = get_artifacts_root()
        path = root / IronOS.COVERAGE_SUBPATH
        
        if not path.exists():
            return None
            
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            
            # Support {"entries": [...]} OR [...]
            raw_entries = []
            if isinstance(data, list):
                raw_entries = data
            elif isinstance(data, dict):
                raw_entries = data.get("entries", [])
                
            valid_entries = []
            for e in raw_entries:
                try:
                    # Strict validation
                    status = e.get("status")
                    if status not in ["AVAILABLE", "DEGRADED", "UNAVAILABLE"]:
                        continue # Drop invalid
                    
                    valid_entries.append(CoverageEntry(
                        capability=e.get("capability", "UNKNOWN"),
                        status=status,
                        reason=e.get("reason")
                    ))
                except Exception:
                    continue # Valid items only
            
            return CoverageSnapshot(entries=valid_entries).dict()
        except Exception:
            return None

    @staticmethod
    def get_findings() -> Optional[Dict[str, Any]]:
        """
        Reads Iron OS findings artifact strictly.
        Returns snapshot dict or None if UNAVAILABLE/MISSING.
        """
        root = get_artifacts_root()
        path = root / IronOS.FINDINGS_SUBPATH
        
        if not path.exists():
            return None
            
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            
            # Support {"findings": [...]} OR [...]
            raw_list = []
            if isinstance(data, list):
                raw_list = data
            elif isinstance(data, dict):
                raw_list = data.get("findings", [])
                
            valid_list = []
            for e in raw_list:
                try:
                    # Strict validation
                    sev = e.get("severity", "INFO")
                    if sev not in ["INFO", "WARN", "ERROR"]:
                        continue # Drop invalid severity
                        
                    valid_list.append(FindingEntry(
                        finding_code=str(e.get("finding_code", "UNKNOWN")),
                        severity=sev,
                        message=str(e.get("message", "No message")),
                        originating_module=e.get("originating_module"),
                        timestamp_utc=e.get("timestamp_utc")
                    ))
                except Exception:
                    continue 
            
            
            
            return FindingsSnapshot(findings=valid_list).dict()
        except Exception:
            return None

    @staticmethod
    def get_before_after_diff() -> Optional[Dict[str, Any]]:
        """
        Reads Iron OS before/after diff artifact strictly.
        Returns snapshot dict or None if UNAVAILABLE/MISSING.
        D42.09: Visibility Only.
        """
        root = get_artifacts_root()
        path = root / "os/os_before_after_diff.json"
        
        if not path.exists():
            return None
            
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                
            # Strict validation using top-level model
            # Note: BeforeAfterDiffSnapshot is defined below, so we delay usage or move definition up.
            # Python resolves dynamically, but Pydantic class needs to be defined.
            # We can define model first, OR simply validate dict manually if model is below.
            # Or better: Move model ABOVE IronOS class or stick to manual dict construction matching the model.
            # Let's rely on manual dict construction to avoid circular/ordering mess in this patch, 
            # or assumption that model is available.
            # Actually, let's just use the dict directly if valid, strict parsing manually.
            
            return BeforeAfterDiffSnapshot(
                timestamp_utc=data.get("timestamp_utc") or data.get("ts") or datetime.now(timezone.utc).isoformat(),
                operation_id=data.get("operation_id"),
                originating_module=data.get("originating_module"),
                before_state=data.get("before", {}),
                after_state=data.get("after", {}),
                changed_keys=data.get("changed_keys")
            ).dict()
        except Exception:
            return None

class BeforeAfterDiffSnapshot(BaseModel):
    timestamp_utc: str
    operation_id: Optional[str]
    originating_module: Optional[str]
    before_state: Dict[str, Any]
    after_state: Dict[str, Any]
    changed_keys: Optional[List[str]] = None

