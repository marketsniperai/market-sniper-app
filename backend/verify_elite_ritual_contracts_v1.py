
import os
import json
import jsonschema
from jsonschema import validate

# Define paths
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCHEMA_DIR = os.path.join(REPO_ROOT, "outputs", "schemas", "elite")
SAMPLE_DIR = os.path.join(REPO_ROOT, "outputs", "samples", "elite")
PROOF_DIR = os.path.join(REPO_ROOT, "outputs", "proofs", "d49_elite_contracts_v1")

# Ensure proof directory exists
if not os.path.exists(PROOF_DIR):
    os.makedirs(PROOF_DIR)

PROOF_FILE = os.path.join(PROOF_DIR, "01_verify.txt")

REQUIRED_PAIRS = [
    ("elite_morning_briefing_v1.schema.json", "elite_morning_briefing_sample.json"),
    ("elite_midday_report_v1.schema.json", "elite_midday_report_sample.json"),
    ("elite_market_resumed_v1.schema.json", "elite_market_resumed_sample.json"),
    ("elite_how_i_did_today_v1.schema.json", "elite_how_i_did_today_sample.json"),
    ("elite_how_you_did_today_v1.schema.json", "elite_how_you_did_today_sample.json"),
    ("elite_sunday_setup_v1.schema.json", "elite_sunday_setup_sample.json"),
]

def verify():
    results = []
    all_passed = True

    print(f"Verifying {len(REQUIRED_PAIRS)} Elite Ritual Contracts...")
    results.append(f"VERIFICATION REPORT: Elite Ritual Contracts v1")
    results.append(f"=============================================")

    for schema_file, sample_file in REQUIRED_PAIRS:
        schema_path = os.path.join(SCHEMA_DIR, schema_file)
        sample_path = os.path.join(SAMPLE_DIR, sample_file)

        # Check existence
        if not os.path.exists(schema_path):
            msg = f"FAIL: Schema not found: {schema_file}"
            print(msg)
            results.append(msg)
            all_passed = False
            continue

        if not os.path.exists(sample_path):
            msg = f"FAIL: Sample not found: {sample_file}"
            print(msg)
            results.append(msg)
            all_passed = False
            continue

        # Load and Validate
        try:
            with open(schema_path, 'r') as sf:
                schema = json.load(sf)
            with open(sample_path, 'r') as df:
                sample = json.load(df)
            
            validate(instance=sample, schema=schema)
            msg = f"PASS: {schema_file} validates {sample_file}"
            print(msg)
            results.append(msg)

        except json.JSONDecodeError as e:
            msg = f"FAIL: JSON Error in {schema_file} or {sample_file}: {str(e)}"
            print(msg)
            results.append(msg)
            all_passed = False
        except jsonschema.exceptions.ValidationError as e:
            msg = f"FAIL: Validation Error for {sample_file}: {e.message}"
            print(msg)
            results.append(msg)
            all_passed = False
        except Exception as e:
            msg = f"FAIL: Unexpected Error: {str(e)}"
            print(msg)
            results.append(msg)
            all_passed = False

    # Final Verdict
    results.append("---------------------------------------------")
    if all_passed:
        results.append("OVERALL STATUS: PASS")
    else:
        results.append("OVERALL STATUS: FAIL")

    # Write Proof
    with open(PROOF_FILE, 'w') as f:
        f.write("\n".join(results))
    
    print(f"Proof written to: {PROOF_FILE}")

if __name__ == "__main__":
    verify()
