
import json
from collections import defaultdict
from backend.artifacts.io import get_artifacts_root, safe_read_or_fallback, atomic_write_json
from backend.os_ops.reliability_reconciler import ReliabilityReconciler

class CalibrationReportEngine:
    """
    D48.BRAIN.04: Aggregates Ledgers into a Calibration Report.
    """
    
    REPORT_PATH = "engine/calibration_report.json"
    
    @staticmethod
    def generate_report():
        # 1. Load Everything
        ledger_path = get_artifacts_root() / ReliabilityReconciler.LEDGER_PATH
        outcomes_path = get_artifacts_root() / ReliabilityReconciler.OUTCOMES_PATH
        
        ledger_map = {} # run_id -> entry
        if ledger_path.exists():
             with open(ledger_path, "r") as f:
                 for line in f:
                     try:
                        r = json.loads(line)
                        ledger_map[r["run_id"]] = r
                     except: pass
                     
        outcomes_map = {} # run_id -> outcome
        if outcomes_path.exists():
             with open(outcomes_path, "r") as f:
                 for line in f:
                    try:
                        o = json.loads(line)
                        outcomes_map[o["run_id"]] = o
                    except: pass
                    
        # 2. Compute Metrics
        total_projections = len(ledger_map)
        total_outcomes = len(outcomes_map)
        
        in_bounds_count = 0
        total_checked = 0
        
        # Breakdown by Source
        source_stats = defaultdict(lambda: {"count": 0, "reconciled": 0, "in_bounds": 0})
        
        for run_id, outcome in outcomes_map.items():
            if run_id not in ledger_map: continue
            
            entry = ledger_map[run_id]
            source = entry.get("source_ladder", "UNKNOWN")
            
            source_stats[source]["count"] += 1
            source_stats[source]["reconciled"] += 1
            
            total_checked += 1
            if outcome.get("is_in_bounds"):
                 in_bounds_count += 1
                 source_stats[source]["in_bounds"] += 1
                 
        # 3. Build Report
        report = {
            "meta": {
                "total_projections_recorded": total_projections,
                "total_outcomes_reconciled": total_outcomes,
                "coverage_pct": (total_outcomes / total_projections * 100) if total_projections > 0 else 0
            },
            "reliability_scores": {
                "global_in_bounds_rate": (in_bounds_count / total_checked * 100) if total_checked > 0 else 0,
                "sample_size": total_checked
            },
            "source_breakdown": dict(source_stats)
        }
        
        atomic_write_json(CalibrationReportEngine.REPORT_PATH, report)
        return report
