
import os
import sys
import json
import shutil

# Paths
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(REPO_ROOT)

from backend.os_intel.elite_ritual_engines.morning_briefing_engine import MorningBriefingEngine
from backend.os_intel.elite_ritual_engines.midday_report_engine import MiddayReportEngine
from backend.os_intel.elite_ritual_engines.market_resumed_engine import MarketResumedEngine
from backend.os_intel.elite_ritual_engines.how_i_did_today_engine import HowIDidTodayEngine
from backend.os_intel.elite_ritual_engines.how_you_did_today_engine import HowYouDidTodayEngine
from backend.os_intel.elite_ritual_engines.sunday_setup_engine import SundaySetupEngine

PROOF_DIR = os.path.join(REPO_ROOT, "outputs", "proofs", "d49_elite_ritual_engines_v1")
PROOF_FILE = os.path.join(PROOF_DIR, "01_verify.txt")

if not os.path.exists(PROOF_DIR):
    os.makedirs(PROOF_DIR)

def verify():
    results = []
    passed = True
    
    results.append("VERIFICATION REPORT: Elite Ritual Engines V1")
    results.append("============================================")

    engines = [
        MorningBriefingEngine(),
        MiddayReportEngine(),
        MarketResumedEngine(),
        HowIDidTodayEngine(),
        HowYouDidTodayEngine(),
        SundaySetupEngine()
    ]

    for engine in engines:
        key = engine.ritual_key
        results.append(f"\nScanning {key}...")
        
        try:
            # FORCE OPEN WINDOW to test schema compliance
            payload = engine.run_and_persist(force_window_open=True)
            
            if not payload:
                results.append(f"FAIL: {key} returned None even with force_window_open=True")
                passed = False
                continue
                
            # Verify Schema Keys
            if "meta" not in payload or "window" not in payload or "sections" not in payload:
                 results.append(f"FAIL: {key} missing top-level keys")
                 passed = False
                 continue
                 
            # Verify Output File Exists
            fname = f"elite_{key.lower()}.json"
            fpath = os.path.join(REPO_ROOT, "outputs", "elite", fname)
            if os.path.exists(fpath):
                 results.append(f"PASS: {key} artifact verified at {fname}")
            else:
                 results.append(f"FAIL: {key} artifact not found")
                 passed = False

        except Exception as e:
            results.append(f"FAIL: Exception in {key}: {str(e)}")
            passed = False

    results.append("\n------------------------------------------")
    results.append("OVERALL STATUS: " + ("PASS" if passed else "FAIL"))
    
    print("\n".join(results))

    with open(PROOF_FILE, 'w') as f:
        f.write("\n".join(results))
    
    print(f"Proof written to {PROOF_FILE}")

if __name__ == "__main__":
    verify()
