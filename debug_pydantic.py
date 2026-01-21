import sys
import os
sys.path.append(os.getcwd())
from backend.os_ops.autofix_tier1 import AutoFixDecisionPath
from datetime import datetime

try:
    print("Attempting to instantiate AutoFixDecisionPath...")
    d = AutoFixDecisionPath(
        run_id="TEST",
        plan_id=None,
        timestamp_utc=datetime.now(),
        trigger_context="CTX",
        overall_status="NO_OP",
        rules_applied=["TEST"],
        actions=[]
    )
    print("Success")
except Exception as e:
    print("Caught Exception:")
    print(e)
    # try to print vars
    if hasattr(e, 'errors'):
        print(e.errors())
