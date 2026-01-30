import os
import shutil
from pathlib import Path

# --- Configuration ---
ROOT_DIR = Path(os.getcwd())
ARCHIVE_ROOT = ROOT_DIR / "_archive" / "d51_post_ewims"
ARCHIVE_TRACE = ARCHIVE_ROOT / "audits_trace"
OUTPUTS_CHECKPOINTS = ROOT_DIR / "outputs" / "checkpoints"

# Buckets
KEEP = []
ARCHIVE = []
IGNORE = []
DELETE = []

# Ensure directories exist
ARCHIVE_ROOT.mkdir(parents=True, exist_ok=True)
ARCHIVE_TRACE.mkdir(parents=True, exist_ok=True)

# --- Helper Functions ---
def read_list(filename):
    p = OUTPUTS_CHECKPOINTS / filename
    if not p.exists(): return []
    return [x.strip() for x in p.read_text(encoding="utf-8", errors="ignore").splitlines() if x.strip()]

def get_all_pending_files():
    modified = read_list("D51_git_diff_names_before.txt")
    untracked = read_list("D51_untracked_before.txt")
    return sorted(list(set(modified + untracked)))

def classify_file(fpath_str):
    f = fpath_str.replace("\\", "/")
    
    # --- IGNORE ---
    if f.startswith("outputs/cache/") or "__pycache__" in f or ".pytest_cache" in f or f.endswith(".pyc") or f.endswith(".log"):
        return "IGNORE", None

    # --- DELETE ---
    if f.endswith("crash_test.log") or f.endswith("error.log"): return "DELETE", None
    if f in ["analysis_fix.txt", "analyze_v1.txt", "debug_audit.txt", "comparison_log.txt", "debug_dates.txt"]: return "DELETE", None
    if f in ["analyze_grouping.py", "analyze_untracked.py", "scan_secrets.py", "classify_counts.py"]: return "DELETE", None
    if f in ["inspect_orchestrator.py", "sanity_output.txt", "verifier_log.txt", "outputs/scan_raw.txt", "debug_hf_server.py", "generate_triage_final.py"]: return "DELETE", None
    if f.startswith("market_sniper_app/") and f.endswith(".txt"): return "DELETE", None
    
    if f == "backend/os_ops/debug_import.py": return "DELETE", None
    # Careful not to delete D51 baseline
    if f.startswith("outputs/checkpoints/") and "D51_" not in f: return "DELETE", None

    # --- ARCHIVE ---
    dest_sub = None
    if f.startswith("implementation_plan_"): return "ARCHIVE", None
    if f.startswith("outputs/proofs/"): return "ARCHIVE", None
    if f.startswith("outputs/samples/"): return "ARCHIVE", None
    if f.startswith("outputs/on_demand_public/"): return "ARCHIVE", None
    if f.startswith("outputs/outputs/"): return "ARCHIVE", None
    if f.startswith("outputs/ledgers/"): return "ARCHIVE", None
    if f.startswith("outputs/elite/"): return "ARCHIVE", None
    if f.startswith("market_sniper_app/tool/"): return "ARCHIVE", None
    if f.startswith("outputs/engine/"): return "ARCHIVE", None
    if f.startswith("outputs/user_memory/"): return "ARCHIVE", None
    if f == "outputs/misfire_report.json": return "ARCHIVE", None
    
    # OS Rule: KEEP SSOT, Archive rest
    if f.startswith("outputs/os/"):
        fname = os.path.basename(f)
        if (fname.startswith("os_registry_snapshot") or 
            fname.startswith("state_snapshot") or 
            "_index" in fname or 
            "_contract" in fname or 
            "_schema_ref" in fname):
            return "KEEP", None
        else:
            return "ARCHIVE", None
            
    # Trace Archive Rule
    if f.startswith("outputs/audits/"):
        if "TRACE" in f:
             return "ARCHIVE_TRACE", ARCHIVE_TRACE # specific dest
        if f in [
            "outputs/audits/D50_EWIMS_FINAL_VERDICT.md",
            "outputs/audits/D50_EWIMS_COVERAGE_SUMMARY.json",
            "outputs/audits/D50_EWIMS_PROMISES_INDEX.json",
            "outputs/audits/D50_EWIMS_CHRONOLOGICAL_MATRIX.md",
            "outputs/audits/D50_EWIMS_GHOST_ZOMBIE_LIST.md"
        ]:
            return "KEEP", None
        return "KEEP", None
    
    # --- New explicit classifications for UNCLASSIFIED ---
    if f == "backend/artifacts/io.py": return "KEEP", None
    if f.startswith("outputs/scripts/"): return "KEEP", None
    if f.startswith("outputs/seals/"): return "KEEP", None

    # --- KEEP ---
    if f.startswith("backend/os_intel/") or f.startswith("backend/os_llm/") or f.startswith("backend/os_ops/"): return "KEEP", None
    if f == "backend/news_engine.py": return "KEEP", None
    if f.startswith("backend/verify_"): return "KEEP", None
    if f.startswith("docs/canon/"): return "KEEP", None
    if f.startswith("outputs/schemas/"): return "KEEP", None
    if f in ["os_registry.json", "openapi.yaml"]: return "KEEP", None
    if f.startswith("market_sniper_app/lib/") or f.startswith("market_sniper_app/test/"): return "KEEP", None
    if f.startswith("market_sniper_app/android/") or f.startswith("market_sniper_app/macos/") or f.startswith("market_sniper_app/linux/") or f.startswith("market_sniper_app/windows/"): return "KEEP", None
        
    return "UNCLASSIFIED", None

# --- Main Logic ---
all_files = get_all_pending_files()
print(f"Processing {len(all_files)} items...")

for f in all_files:
    bucket, dest_override = classify_file(f)
    src_path = ROOT_DIR / f
    
    if not src_path.exists():
        print(f"Skipping missing: {f}")
        continue
        
    if bucket == "DELETE":
        try:
            os.remove(src_path)
            print(f"DELETED: {f}")
        except Exception as e:
            print(f"ERROR DELETING {f}: {e}")
            
    elif bucket == "ARCHIVE" or bucket == "ARCHIVE_TRACE":
        dest_root = dest_override if dest_override else ARCHIVE_ROOT
        # Maintain relative structure inside archive unless override
        if dest_override:
            dest_path = dest_root / os.path.basename(f)
        else:
            dest_path = dest_root / f
            
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            shutil.move(str(src_path), str(dest_path))
            print(f"ARCHIVED: {f} -> {dest_path}")
        except Exception as e:
            print(f"ERROR ARCHIVING {f}: {e}")
            
    elif bucket == "IGNORE":
        print(f"IGNORED: {f}")
        
    elif bucket == "KEEP":
        print(f"KEPT: {f}")
        
    else:
        print(f"UNCLASSIFIED (SKIPPED): {f}")

print("Cleanup Complete.")
