import os
import json
import sys
from pathlib import Path

class FreezeEnforcer:
    """
    Day 30.1: Enforces Core OS Freeze Law.
    Validates presence of canonical docs and critical config.
    """
    
    REQUIRED_FILES = [
        "docs/canon/LAUNCH_FREEZE_LAW.md",
        "docs/canon/RELEASE_CHECKLIST.md",
        "os_kill_switches.json",
        "os_registry.json"
    ]
    
    CORE_MODULES = [
        "OS.Infra.API",
        "OS.Infra.Gates",
        "OS.Ops.Pipeline",
        "OS.Ops.WarRoom",
        "OS.Ops.ShadowRepair",
        "OS.Intel.Handoff"
    ]

    @staticmethod
    def enforce() -> dict:
        report = {
            "status": "PASS",
            "missing_files": [],
            "registry_violations": [],
            "kill_switch_status": "UNKNOWN"
        }
        
        root = Path(os.getcwd())
        
        # 1. Check Required Files
        for f in FreezeEnforcer.REQUIRED_FILES:
            if not (root / f).exists():
                report["missing_files"].append(f)
                report["status"] = "FAIL"
                
        # 2. Validate Kill Switches
        ks_path = root / "os_kill_switches.json"
        if ks_path.exists():
            try:
                with open(ks_path, "r") as f:
                    data = json.load(f)
                    report["kill_switch_status"] = data.get("switches", {})
            except:
                report["status"] = "FAIL"
                report["kill_switch_status"] = "ERROR_READING"
                
        # 3. Validate Registry (Are Core Modules present?)
        # We don't have "is_core_os" flag in registry yet, but we check if ID exists at least.
        # Ideally, we should add "is_core_os": true to registry entries, but user said "Zero refactor grande".
        # So we just check existence.
        reg_path = root / "os_registry.json"
        if reg_path.exists():
             try:
                 with open(reg_path, "r") as f:
                     reg = json.load(f)
                     modules = {m["module_id"] for m in reg.get("modules", [])}
                     
                     for core in FreezeEnforcer.CORE_MODULES:
                         if core not in modules:
                             report["registry_violations"].append(f"Missing Core Module: {core}")
                             report["status"] = "FAIL"
             except:
                 report["status"] = "FAIL"
                 report["registry_violations"].append("Registry Read Fail")
        
        return report

if __name__ == "__main__":
    rep = FreezeEnforcer.enforce()
    print(json.dumps(rep, indent=2))
    if rep["status"] != "PASS":
        sys.exit(1)
