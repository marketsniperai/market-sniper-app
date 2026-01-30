
import os
import json

# Paths
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INDEX_PATH = os.path.join(REPO_ROOT, "outputs", "os", "os_knowledge_index.json")
PROOF_DIR = os.path.join(REPO_ROOT, "outputs", "proofs", "d49_os_knowledge_index_v1")
PROOF_FILE = os.path.join(PROOF_DIR, "01_verify.txt")

# Ensure proof dir
if not os.path.exists(PROOF_DIR):
    os.makedirs(PROOF_DIR)

def verify():
    results = []
    passed = True
    
    results.append("VERIFICATION REPORT: OS Knowledge Index v1")
    results.append("==========================================")

    if not os.path.exists(INDEX_PATH):
        msg = f"FAIL: Index not found at {INDEX_PATH}"
        print(msg)
        results.append(msg)
        # Write early fail
        with open(PROOF_FILE, 'w') as f:
            f.write("\n".join(results))
        return

    try:
        with open(INDEX_PATH, 'r') as f:
            data = json.load(f)
        
        # Top level keys
        required_keys = ["modules", "surfaces", "artifacts", "lexicon_constraints"]
        for key in required_keys:
            if key not in data:
                msg = f"FAIL: Missing top-level key '{key}'"
                results.append(msg)
                passed = False
            else:
                count = len(data[key])
                if count == 0:
                     msg = f"warn: Key '{key}' is empty array."
                     results.append(msg)
                     # Not necessarily a fail, but supicious for modules/surfaces
                     if key == "modules": passed = False
                else:
                    results.append(f"PASS: '{key}' present with {count} items.")

        # Structure Validation (Sample)
        if passed:
            if "modules" in data:
                m0 = data["modules"][0]
                if "id" not in m0 or "why" not in m0:
                     msg = "FAIL: Module structure missing 'id' or 'why'."
                     results.append(msg)
                     passed = False
            
            if "surfaces" in data:
                 s0 = data["surfaces"][0]
                 if "id" not in s0 or "paths" not in s0:
                      msg = "FAIL: Surface structure missing 'id' or 'paths'."
                      results.append(msg)
                      passed = False

    except Exception as e:
        msg = f"FAIL: Exception during verification: {str(e)}"
        results.append(msg)
        passed = False

    results.append("------------------------------------------")
    results.append("OVERALL STATUS: " + ("PASS" if passed else "FAIL"))
    
    print("\n".join(results))

    with open(PROOF_FILE, 'w') as f:
        f.write("\n".join(results))
    
    print(f"Proof written to {PROOF_FILE}")

if __name__ == "__main__":
    verify()
