import os
import sys
import json
import shutil
from pathlib import Path

# Add repo root to path
sys.path.append(os.getcwd())

from backend.agms_autopilot_handoff import AGMSAutopilotHandoff
from backend.autofix_control_plane import AutoFixControlPlane
from backend.war_room import WarRoom
from backend.artifacts.io import get_artifacts_root, atomic_write_json

def run_verification():
    print("=== DAY 23 VERIFICATION SUITE ===")
    
    outputs_dir = Path("outputs/runtime/day_23")
    os.makedirs(outputs_dir, exist_ok=True)
    root = get_artifacts_root()
    p_suggestions = root / "runtime/agms/agms_shadow_suggestions.json"
    p_suggestions_bak = root / "runtime/agms/agms_shadow_suggestions.json.bak_verify"
    
    # 1. BASELINE RUN
    print("\n[1] Baseline AGMS Handoff...")
    # Empty run
    res_base = AGMSAutopilotHandoff.generate_handoff()
    print(f"Baseline Status: {res_base.get('status')}")
    
    with open(outputs_dir / "day_23_baseline.txt", "w") as f:
        f.write(json.dumps(res_base, indent=2))
        
    # 2. FORCED HANDOFF (Inject Suggestion)
    print("\n[2] Forced Handoff Generation...")
    
    if p_suggestions.exists():
        shutil.move(str(p_suggestions), str(p_suggestions_bak))
        
    generated_handoff = None
    try:
        # Mock Suggestion (High Confidence)
        mock_suggestions = {
            "timestamp_utc": "2026-01-01T12:00:00Z",
            "suggestions": [
                {
                    "suggestion_id": "test_sug_1",
                    "mapped_playbook_id": "PB-T1-MISFIRE-LIGHT",
                    "severity": "HIGH",
                    "confidence": 0.9,
                    "safety_note": "SUGGEST-ONLY"
                }
            ]
        }
        atomic_write_json(str(p_suggestions.relative_to(root)), mock_suggestions)
        
        # Run Handoff Engine
        res_forced = AGMSAutopilotHandoff.generate_handoff()
        generated_handoff = res_forced.get("handoff")
        
        if generated_handoff:
            print(f"Handoff Generated: YES")
            print(f"Playbook: {generated_handoff['suggested_playbook_id']}")
            print(f"Token: {generated_handoff['token'][:10]}...")
        else:
            print("FAIL: No handoff generated from high confidence suggestion.")
            
        with open(outputs_dir / "day_23_handoff_generated.txt", "w") as f:
            f.write(json.dumps(res_forced, indent=2))
            
    finally:
        pass # Keep mock for execution text, restore at very end if needed
        
    if not generated_handoff:
        print("Skipping Execute tests due to gen failure.")
        sys.exit(1)

    # 3. EXECUTION GATES
    print("\n[3] Execution Gates (Autofix)...")
    
    # A. No Key / Auth
    print("Test A: No Auth...")
    res_no_key = AutoFixControlPlane.execute_from_handoff(generated_handoff, founder_key=None)
    print(f"Result: {res_no_key['status']} (Reason: {res_no_key.get('reason_codes')})")
    
    if "FAILED_GUARDRAIL" not in res_no_key["status"] or "AUTH_REQUIRED" not in res_no_key.get("reason_codes", []):
         print("FAIL: Did not block unauthenticated execution.")
         
    with open(outputs_dir / "day_23_execute_no_key.txt", "w") as f:
         f.write(json.dumps(res_no_key, indent=2))

    # B. With Founder Key (Checking Cooldown or Trigger)
    print("Test B: With Founder Key...")
    # Note: PB-T1-MISFIRE-LIGHT maps to RUN_PIPELINE_LIGHT
    # Cooldown might be active from previous days or empty state.
    res_auth = AutoFixControlPlane.execute_from_handoff(generated_handoff, founder_key="VALID-KEY-MOCK")
    print(f"Result: {res_auth['status']}")
    
    # Verify it attempted to Validate Token at least
    # If invalid token, it would fail guardrail. If valid, passes to Cooldown/Allowlist.
    if res_auth["status"] == "FAILED_GUARDRAIL" and "INVALID_TOKEN" in res_auth["reason_codes"]:
        print("FAIL: Token validation failed despite being fresh.")
    else:
        print("PASS: Token Validated.")
        
    with open(outputs_dir / "day_23_execute_attempt.txt", "w") as f:
         f.write(json.dumps(res_auth, indent=2))

    # 4. WAR ROOM CHECK
    print("\n[4] War Room Integration...")
    dashboard = WarRoom.get_dashboard()
    intel_surface = dashboard["modules"].get("agms", {}).get("intelligence", {})
    autopilot = intel_surface.get("autopilot", {})
    
    print(f"Latest Handoff Visible: {autopilot.get('latest_handoff') is not None}")
    print(f"Latest Execution Visible: {autopilot.get('latest_execution') is not None}")
    
    if not autopilot.get("latest_handoff"):
        print("FAIL: War Room missing Autopilot lane.")
        
    with open(outputs_dir / "day_23_war_room_autopilot_lane.txt", "w") as f:
         f.write(json.dumps(autopilot, indent=2))

    # Cleanup
    if p_suggestions.exists():
        os.remove(p_suggestions)
    if p_suggestions_bak.exists():
        shutil.move(str(p_suggestions_bak), str(p_suggestions))

    print("\n=== VERIFICATION COMPLETE ===")

if __name__ == "__main__":
    run_verification()
