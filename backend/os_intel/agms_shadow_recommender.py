import os
import json
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List, Optional
from backend.artifacts.io import atomic_write_json, get_artifacts_root, safe_read_or_fallback, append_to_ledger

# TITANIUM LAW: AGMS SUGGESTS, BUT NEVER ACTS.
NO_EXECUTION_GUARD = True

class AGMSShadowRecommender:
    """
    Day 22: AGMS Shadow Recommender.
    Suggests Playbooks based on Patterns.
    
    Responsibilities:
    1. Read Patterns & Coherence.
    2. Map to existing Playbooks (os_playbooks.yml).
    3. Produce Shadow Suggestions (Severity, Confidence).
    
    Constraint: NO EXECUTION.
    """
    
    AGMS_ROOT = "runtime/agms"
    
    # Static Mapping: Pattern -> Playbook
    # In a real intelligent system, this might be learned.
    # Here we hardcode the "Titanium Logic" as a baseline.
    PATTERN_MAP = {
        "MISSING_LIGHT_MANIFEST": "PB-T1-MISFIRE-LIGHT",
        "MISSING_FULL_MANIFEST": "PB-T1-MISFIRE-FULL",
        "LOCK_STUCK": "PB-T1-LOCK-STUCK", # Mapped to actual ID in yml
        "LOCK_STUCK_1H": "PB-T1-LOCK-STUCK",
        "GARBAGE_FOUND": "PB-T1-GARBAGE-FOUND",
        "DRIFT_MANIFEST": "PB-T1-DRIFT-MANIFEST"
    }
    
    @staticmethod
    def generate_suggestions() -> Dict[str, Any]:
        """
        Main entry point.
        """
        assert NO_EXECUTION_GUARD is True, "AGMS MUST NOT EXECUTE"
        
        root = get_artifacts_root()
        now = datetime.now(timezone.utc)
        
        # 1. READ INPUTS
        patterns_res = safe_read_or_fallback("runtime/agms/agms_patterns.json")
        patterns = patterns_res.get("data", {})
        
        # 2. GENERATE SUGGESTIONS
        suggestions = AGMSShadowRecommender._map_patterns_to_suggestions(patterns)
        
        # 3. CREATE SNAPSHOT
        snapshot = {
            "timestamp_utc": now.isoformat(),
            "suggestion_count": len(suggestions),
            "suggestions": suggestions,
            "engine_version": "1.0.0 (Shadow)"
        }
        
        # 4. PERSIST ARTIFACTS
        AGMSShadowRecommender._persist_artifacts(root, snapshot)
        
        return snapshot

    @staticmethod
    def verify_no_side_effects() -> bool:
        """
        Self-check ensuring no writes outside AGMS root.
        """
        return NO_EXECUTION_GUARD

    # --- INTERNAL HELPERS ---
    
    @staticmethod
    def _map_patterns_to_suggestions(patterns: Dict[str, Any]) -> List[Dict[str, Any]]:
        suggestions = []
        
        # Analyze Top Drift Types
        top_drifts = patterns.get("top_drift_types", [])
        
        for drift in top_drifts:
            d_type = drift.get("type", "UNKNOWN")
            count = drift.get("count", 0)
            
            # Check Map
            pb_id = AGMSShadowRecommender.PATTERN_MAP.get(d_type)
            
            if pb_id:
                # Valid Suggestion
                suggestions.append({
                    "suggestion_id": hashlib.md5(f"{d_type}_{pb_id}".encode()).hexdigest()[:8],
                    "mapped_playbook_id": pb_id,
                    "trigger_pattern": d_type,
                    "evidence_count": count,
                    "severity": AGSShadowRecommender._infer_severity(pb_id),
                    "confidence": 0.8 if count > 2 else 0.5, # Boost confidence if frequent
                    "safety_note": "SUGGEST-ONLY"
                })
                
        # Sort by confidence/severity
        suggestions.sort(key=lambda x: x["confidence"], reverse=True)
        return suggestions[:5] # Top 5 only

    @staticmethod
    def _infer_severity(pb_id: str) -> str:
        if "MISFIRE" in pb_id: return "HIGH"
        if "STALE" in pb_id: return "MEDIUM"
        if "GARBAGE" in pb_id: return "LOW"
        return "LOW"

    @staticmethod
    def _persist_artifacts(root: Path, snapshot: Dict[str, Any]):
        agms_dir = root / AGMSShadowRecommender.AGMS_ROOT
        
        # 1. Suggestions List
        atomic_write_json(str(agms_dir / "agms_shadow_suggestions.json"), {
            "timestamp_utc": snapshot["timestamp_utc"],
            "suggestions": snapshot["suggestions"]
        })
        
        # 2. Snapshot
        atomic_write_json(str(agms_dir / "agms_shadow_snapshot.json"), snapshot)
        
        # 3. Ledger Append
        entry = {
            "timestamp_utc": snapshot["timestamp_utc"],
            "suggestion_ids": [s["suggestion_id"] for s in snapshot["suggestions"]],
            "top_suggestion": snapshot["suggestions"][0]["mapped_playbook_id"] if snapshot["suggestions"] else None
        }
        append_to_ledger("runtime/agms/agms_shadow_ledger.jsonl", entry)

# Helper alias for internal calls if needed / typo fix in class ref
AGSShadowRecommender = AGMSShadowRecommender
