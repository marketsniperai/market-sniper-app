import json
import os
import sys
from pathlib import Path
import jsonschema
from datetime import datetime

# Schema Authority V1 Verifier
# Validates critical OS artifacts against strict contracts (schemas).

ROOT = Path(os.getcwd())
SCHEMAS_DIR = ROOT / "outputs/schemas"
PROOFS_DIR = ROOT / "outputs/proofs/d48_brain_01_schema_authority_v1"
PROOFS_DIR.mkdir(parents=True, exist_ok=True)

# Mapping: Artifact -> Schema
MAPPING = [
    {
        "artifact": ROOT / "outputs/os/projection/projection_report_daily.json",
        "schema": SCHEMAS_DIR / "projection_report_v1.schema.json",
        "critical": True
    },
    {
        "artifact": ROOT / "outputs/os/projection/projection_report_weekly.json",
        "schema": SCHEMAS_DIR / "projection_report_v1.schema.json",
        "critical": False # Optional
    },
    {
        "artifact": ROOT / "outputs/engine/news_digest.json",
        "schema": SCHEMAS_DIR / "news_digest_v1.schema.json",
        "critical": True
    },
    {
        "artifact": ROOT / "outputs/engine/economic_calendar.json",
        "schema": SCHEMAS_DIR / "economic_calendar_v1.schema.json",
        "critical": True
    },
    {
        "artifact": ROOT / "outputs/samples/on_demand_context_sample.json",
        "schema": SCHEMAS_DIR / "on_demand_context_v1.schema.json",
        "critical": True
    }
]

def load_json(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def run_verification():
    log_lines = []
    log_lines.append(f"Schema Authority V1 Verification - {datetime.utcnow().isoformat()} UTC")
    log_lines.append(f"Schema Lib: jsonschema {jsonschema.__version__}")
    log_lines.append("-" * 60)

    exit_code = 0
    schema_list = []
    artifact_paths = []

    for item in MAPPING:
        art_path = item["artifact"]
        sch_path = item["schema"]
        is_crit = item["critical"]
        
        schema_list.append(str(sch_path.relative_to(ROOT)))
        
        if not sch_path.exists():
            log_lines.append(f"[FAIL] Missing Schema: {sch_path}")
            exit_code = 1
            continue

        if not art_path.exists():
            if is_crit:
                log_lines.append(f"[FAIL] Missing Critical Artifact: {art_path}")
                exit_code = 1
            else:
                log_lines.append(f"[WARN] Missing Optional Artifact: {art_path}")
            continue
            
        artifact_paths.append(str(art_path.relative_to(ROOT)))

        try:
            artifact_data = load_json(art_path)
            schema_data = load_json(sch_path)
            
            jsonschema.validate(instance=artifact_data, schema=schema_data)
            log_lines.append(f"[PASS] {art_path.name}")
            
        except jsonschema.exceptions.ValidationError as e:
            log_lines.append(f"[FAIL] {art_path.name} validation failed: {e.message}")
            # Also log path if available
            if e.path:
                log_lines.append(f"       Path: {list(e.path)}")
            exit_code = 1
        except Exception as e:
            log_lines.append(f"[ERR]  {art_path.name} exception: {str(e)}")
            exit_code = 1

    # Write Proofs
    with open(PROOFS_DIR / "01_verify_schema.txt", "w") as f:
        f.write("\n".join(log_lines))
        
    with open(PROOFS_DIR / "02_schema_list.txt", "w") as f:
        f.write("\n".join(schema_list))
        
    with open(PROOFS_DIR / "03_sample_artifacts_paths.txt", "w") as f:
        f.write("\n".join(artifact_paths))
        
    # Dummy diff (new file creation)
    with open(PROOFS_DIR / "00_diff.txt", "w") as f:
        f.write("Schema Authority V1 initialized. No prior state to diff.")

    print("\n".join(log_lines))
    if exit_code == 0:
        print("\nSUCCESS: All critical schemas validated.")
    else:
        print("\nFAILURE: Schema validation errors found.")
        
    sys.exit(exit_code)

if __name__ == "__main__":
    run_verification()
