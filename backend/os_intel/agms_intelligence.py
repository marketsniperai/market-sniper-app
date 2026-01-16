import os
import json
import collections
from datetime import datetime, timezone, timedelta
from typing import Dict, Any, List, Optional
from pathlib import Path
from backend.artifacts.io import atomic_write_json, get_artifacts_root, safe_read_or_fallback

# TITANIUM LAW: AGMS INTELLIGENCE IS ANALYSIS ONLY
NO_EXECUTION_GUARD = True

class AGMSIntelligence:
    """
    Day 21: AGMS Intelligence (Shadow Mode).
    Pattern Detection, Coherence Scoring, and Timeline Compression.
    
    Responsibilities:
    1. Read History (Ledgers).
    2. Detect Patterns (Drift Frequency).
    3. Measure Coherence (Score & Trend).
    4. Compress Timeline (Weekly Summary).
    
    Constraint: NO EXECUTION. NO RECOMMENDATIONS.
    """
    
    AGMS_ROOT = "runtime/agms"
    
    @staticmethod
    def generate_intelligence() -> Dict[str, Any]:
        """
        Main entry point. Reads ledgers, computes intelligence, writes artifacts.
        """
        assert NO_EXECUTION_GUARD is True, "AGMS MUST NOT EXECUTE"
        
        root = get_artifacts_root()
        now = datetime.now(timezone.utc)
        
        # 1. READ HISTORY
        ledgers = AGMSIntelligence._read_ledgers(root)
        
        # 2. ANALYZE PATTERNS
        patterns = AGMSIntelligence._analyze_patterns(ledgers)
        
        # 3. COMPUTE COHERENCE
        coherence = AGMSIntelligence._compute_coherence(patterns, ledgers)
        
        # 4. COMPRESS TIMELINE
        summary = AGMSIntelligence._compress_timeline(ledgers, now)
        
        # 5. PERSIST ARTIFACTS
        AGMSIntelligence._persist_artifacts(root, patterns, coherence, summary)
        
        # Day 34: Black Box Hook
        from backend.os_ops.black_box import BlackBox
        BlackBox.record_event("AGMS_THINK", {"coherence": coherence, "top_pattern": patterns.get("top_drift_types", [])[:1]}, {})

        return {
            "patterns": patterns,
            "coherence": coherence,
            "summary": summary,
            "timestamp_utc": now.isoformat()
        }

    @staticmethod
    def _read_ledgers(root: Path) -> Dict[str, List[Dict[str, Any]]]:
        """
        Reads AGMS and Autofix ledgers safely.
        """
        data = {"agms": [], "autofix": []}
        
        # AGMS Ledger
        p_agms = root / "runtime/agms/agms_ledger.jsonl"
        if p_agms.exists():
            with open(p_agms, "r", encoding="utf-8") as f:
                data["agms"] = [json.loads(line) for line in f if line.strip()]
                
        # Autofix Ledger (for cross-ref if needed, mainly AGMS drift matters here)
        p_af = root / "runtime/autofix/autofix_ledger.jsonl"
        if p_af.exists():
            with open(p_af, "r", encoding="utf-8") as f:
                data["autofix"] = [json.loads(line) for line in f if line.strip()]
                
        return data

    @staticmethod
    def _analyze_patterns(ledgers: Dict[str, List[Dict[str, Any]]]) -> Dict[str, Any]:
        """
        Detects drift frequency and persistent issues.
        """
        drift_counts = collections.Counter()
        module_counts = collections.Counter()
        
        for entry in ledgers["agms"]:
            drifts = entry.get("drift_deltas", [])
            for d in drifts:
                drift_counts[d] += 1
                # Infer module from drift string (heuristic)
                if "MANIFEST" in d: module_counts["PIPELINE"] += 1
                elif "LOCK" in d: module_counts["LOCK_MANAGER"] += 1
                elif "MISFIRE" in d: module_counts["MISFIRE_MONITOR"] += 1
                else: module_counts["UNKNOWN"] += 1
                
        total_drifts = sum(drift_counts.values())
        
        return {
            "top_drift_types": [
                {"type": k, "count": v, "percentage": round((v/total_drifts)*100, 1) if total_drifts > 0 else 0}
                for k, v in drift_counts.most_common(5)
            ],
            "unstable_modules": [
                {"module": k, "count": v} for k, v in module_counts.most_common(3)
            ],
            "total_drift_events": total_drifts
        }

    @staticmethod
    def _compute_coherence(patterns: Dict[str, Any], ledgers: Dict[str, List]) -> Dict[str, Any]:
        """
        Calculates Coherence Score (0-100).
        Base 100.
        -1 per drift event in last 24h (up to cap).
        """
        score = 100
        explanation = []
        
        # Simple Logic: Count drifts in last N entries (proxy for time if not parsing TS strictly)
        # Better: Parse last 24h
        recent_drifts = 0
        if ledgers["agms"]:
            # Assume sorted or just take tail 50
            tail = ledgers["agms"][-50:] 
            for entry in tail:
                 recent_drifts += len(entry.get("drift_deltas", []))
        
        # Penalty
        penalty = min(recent_drifts * 2, 40) # Max penalty 40 points for drift
        score -= penalty
        
        if penalty > 0:
            explanation.append(f"Penalty -{penalty} due to recent drift events.")
        else:
            explanation.append("System Coherent. No recent drift.")
            
        # Trend
        # Compare first half of tail vs second half
        trend = "FLAT"
        if len(ledgers["agms"]) > 10:
             mid = len(ledgers["agms"]) // 2
             early = ledgers["agms"][:mid]
             late = ledgers["agms"][mid:]
             d_early = sum(len(e.get("drift_deltas", [])) for e in early)
             d_late = sum(len(e.get("drift_deltas", [])) for e in late)
             
             if d_late > d_early: trend = "DOWN" # More errors recently
             elif d_late < d_early: trend = "UP" # Improving
             
        return {
            "score": score,
            "trend": trend,
            "explanation": explanation
        }

    @staticmethod
    def _compress_timeline(ledgers: Dict[str, List], now: datetime) -> Dict[str, Any]:
        """
        Weekly summary of significant events.
        """
        # Placeholder for complex compression.
        # Returns simple counts for defined windows.
        return {
            "window": "LAST_7_DAYS",
            "drift_events": len(ledgers["agms"]),
            "autofix_observations": len(ledgers["autofix"]),
            "generated_at": now.isoformat()
        }

    @staticmethod
    def _persist_artifacts(root: Path, patterns, coherence, summary):
        agms_dir = root / AGMSIntelligence.AGMS_ROOT
        
        atomic_write_json(str(agms_dir / "agms_patterns.json"), patterns)
        atomic_write_json(str(agms_dir / "agms_coherence_snapshot.json"), coherence)
        atomic_write_json(str(agms_dir / "agms_weekly_summary.json"), summary)
