
import os
import sys

# Ensure backend modules can be imported
sys.path.append(os.getcwd())

from backend.os_llm.elite_llm_boundary import EliteLLMBoundary

def verify_integration():
    print("=== D49 Elite LLM Key Integration Verification ===")
    
    # 1. Check Env Var Presence
    key_val = os.environ.get("GEMINI_API_KEY")
    has_key = key_val is not None and len(key_val) > 0
    print(f"[Check] GEMINI_API_KEY present: {has_key}")
    
    if has_key:
        print("[Check] Key is present (redacted):", key_val[:4] + "..." + key_val[-4:])
    else:
        print("[Check] No GEMINI_API_KEY found in environment.")

    # 2. Instantiate Boundary (triggers runtime log)
    print("\n[Action] Initializing EliteLLMBoundary...")
    boundary = EliteLLMBoundary()
    
    # 3. Sample Request
    print("\n[Action] Sending Sample Request (Fallback Test if no key)...")
    response = boundary.run_safe_query("Test Query", {"screen_id": "VERIFICATION"})
    print(f"[Response]: {response}")
    
    # 4. Verification Logic
    if has_key:
        if "OS: LLM unavailable" in response:
            print("[FAIL] Key present but fallback triggered? (Maybe invalid key or quota)")
        else:
            print("[SUCCESS] Key present and response generated (or at least attempted beyond fallback).")
            # Note: Actual generation depends on valid key.
    else:
        if response == "OS: LLM unavailable / CALIBRATING":
            print("[SUCCESS] Fallback Correctly Triggered.")
        else:
            print(f"[FAIL] Unexpected Fallback Message: {response}")

if __name__ == "__main__":
    verify_integration()
