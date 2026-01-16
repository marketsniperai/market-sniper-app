import os
import json
import yaml # Assuming availability or fallback
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Any
from backend.artifacts.io import atomic_write_json, get_artifacts_root, safe_read_or_fallback

# Canonical List of Known Patterns (The Universe of Symptoms)
KNOWN_PATTERNS = [
    # Pipeline
    "MISSING_FULL_MANIFEST", "MANIFEST_MISSING", "MISSING_LIGHT_MANIFEST",
    "FULL_MANIFEST_STALE", "full manifest age > 26h",
    "LIGHT_MANIFEST_STALE", "light manifest age > 15m",
    # Hygiene
    "LOCK_HELD", "os_lock.json age > 1h",
    "GARBAGE_FILES_FOUND", "found .tmp or .bak files older than 1h",
    "MANIFEST_DRIFT", "missing critical manifest file",
    # API
    "API_ERROR_RATE_HIGH", "API_LATENCY_HIGH",
    # Disk
    "DISK_USAGE_HIGH", "DISK_USAGE_CRITICAL",
    # Gates
    "GATE_LOCKED_Unexpected", "CONTRACT_INVALID", "SCHEMA_MISMATCH",
    # AGMS
    "AGMS_DRIFT_HIGH", "AGMS_COHERENCE_LOW", "SHADOW_FLOOD",
    # Auth
    "AUTH_FAILURE_SPIKE",
    # Data
    "DATA_GAP_DETECTED", "CHECKSUM_MISMATCH",
    # Sys
    "MEMORY_USAGE_HIGH", "STARTUP_LATENCY_HIGH",
    # UX
    "DASHBOARD_EMPTY", "CLIENT_ERROR_SPIKE",
    # Cron
    "CRON_MISSED", "JOB_TIMEOUT",
    # Fallback
    "UNKNOWN"
]

PLAYBOOK_REGISTRY_PATH = "os_playbooks.yml"

class PlaybookCoverageScanner:
    """
    Day 28.01: Scans Playbook Registry to ensure coverage of Known Patterns.
    """
    
    @staticmethod
    def scan_coverage() -> Dict[str, Any]:
        root = get_artifacts_root()
        now = datetime.now(timezone.utc)
        
        # 1. Load Playbooks
        playbooks = PlaybookCoverageScanner._load_playbooks_safe()
        
        # 2. Build Map: Pattern -> Playbooks
        pattern_map = {p: [] for p in KNOWN_PATTERNS}
        
        for pb in playbooks:
            # V2 Schema: conditions.pattern_keys
            # V1 Fallback: symptoms
            keys = pb.get("conditions", {}).get("pattern_keys", [])
            if not keys:
                 keys = pb.get("symptoms", [])
                 
            for k in keys:
                if k in pattern_map:
                    pattern_map[k].append(pb["playbook_id"])
                else:
                    # Found a pattern in playbook NOT in KNOWN_PATTERNS (Config Drift?)
                    pattern_map[k] = [pb["playbook_id"]]

        # 3. Analyze Coverage
        covered = [p for p, pbs in pattern_map.items() if len(pbs) > 0 and p in KNOWN_PATTERNS]
        uncovered = [p for p in KNOWN_PATTERNS if len(pattern_map.get(p, [])) == 0]
        extra_mapped = [p for p in pattern_map.keys() if p not in KNOWN_PATTERNS] # Patterns in PBs but not in Canon list
        
        status = "PASS"
        if len(uncovered) > 0:
            status = "WARN" # Uncovered patterns exist
            
        result = {
            "schema_version": "1.0",
            "as_of_utc": now.isoformat(),
            "status": status,
            "metrics": {
                "total_playbooks": len(playbooks),
                "patterns_known": len(KNOWN_PATTERNS),
                "patterns_covered": len(covered),
                "patterns_uncovered": len(uncovered),
                "patterns_extra": len(extra_mapped)
            },
            "uncovered_patterns": uncovered,
            "mapping_table": {k: v for k, v in pattern_map.items() if len(v) > 0} 
        }
        
        # 4. Persist
        PlaybookCoverageScanner._persist(result)
        
        return result

    @staticmethod
    def _load_playbooks_safe() -> List[Dict[str, Any]]:
        # Repo root assumption
        p_path = Path(os.getcwd()) / PLAYBOOK_REGISTRY_PATH
        if not p_path.exists():
             return []
             
        try:
             with open(p_path, "r", encoding="utf-8") as f:
                 data = yaml.safe_load(f)
                 return data.get("playbooks", [])
        except ImportError:
             # Fallback manual text parse if no yaml?
             # For 28.01 let's assume yaml or use manual parser if strictly needed.
             # Given we just wrote the file in YAML, and environment might check HAS_YAML.
             # Re-implementing specific parser for V2 is risky. 
             # Let's hope for PyYAML or use simple one.
             return PlaybookCoverageScanner._manual_parse_v2(p_path)
        except Exception:
             return []

    @staticmethod
    def _manual_parse_v2(path: Path) -> List[Dict[str, Any]]:
        # Quick & Dirty V2 Parser (Only if YAML fails)
        # Matches "- playbook_id:" ...
        playbooks = []
        current = {}
        with open(path, "r", encoding="utf-8") as f:
            lines = f.readlines()
            
        for line in lines:
            line = line.strip()
            if line.startswith("- playbook_id:"):
                if current: playbooks.append(current)
                current = {"playbook_id": line.split(":", 1)[1].strip()}
            elif line.startswith("pattern_keys:"):
                # Very rough list parse: pattern_keys: ["A", "B"]
                val = line.split(":", 1)[1].strip()
                val = val.strip("[]").replace('"', '').replace("'", "")
                keys = [k.strip() for k in val.split(",")]
                if "conditions" not in current: current["conditions"] = {}
                current["conditions"]["pattern_keys"] = keys
                
        if current: playbooks.append(current)
        return playbooks
        
    @staticmethod
    def _persist(result: Dict[str, Any]):
        root = get_artifacts_root()
        out_dir = root / "runtime/playbooks"
        os.makedirs(out_dir, exist_ok=True)
        
        atomic_write_json(str(out_dir / "playbook_coverage_report.json"), result)
        
        # Text Summary
        lines = [
            f"PLAYBOOK COVERAGE REPORT [{result['as_of_utc']}]",
            f"Status: {result['status']}",
            f"Playbooks: {result['metrics']['total_playbooks']}",
            f"Coverage: {result['metrics']['patterns_covered']}/{result['metrics']['patterns_known']} ({result['metrics']['patterns_uncovered']} Uncovered)",
            "",
            "UNCOVERED PATTERNS:"
        ]
        if result["uncovered_patterns"]:
            for p in result["uncovered_patterns"]:
                lines.append(f" - {p}")
        else:
            lines.append(" (None)")
            
        with open(out_dir / "playbook_coverage_report.txt", "w") as f:
            f.write("\n".join(lines))

if __name__ == "__main__":
    # Self-run
    print(json.dumps(PlaybookCoverageScanner.scan_coverage(), indent=2))
