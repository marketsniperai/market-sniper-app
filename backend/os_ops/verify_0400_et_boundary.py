
import sys
import os
from datetime import datetime, timezone, timedelta

# Import target
sys.path.append(os.getcwd())
from backend.os_ops.on_demand_tier_enforcer import OnDemandTierEnforcer

def test_time(dt_utc: datetime, label: str):
    bucket = OnDemandTierEnforcer._compute_bucket_for_dt(dt_utc)
    print(f"[{label}] UTC: {dt_utc} -> BUCKET: {bucket}")

def main():
    print("=== D47.HF16 04:00 ET RESET SYNC PROOF ===")
    print("Rule: Day starts at 04:00 ET. If time < 04:00 ET, it is PREVIOUS day.")
    print("-" * 50)

    # 1. Standard Time (e.g., Jan 27 2026)
    # UTC-5. 04:00 ET = 09:00 UTC.
    # 03:59 ET = 08:59 UTC -> Should be Jan 26
    # 04:00 ET = 09:00 UTC -> Should be Jan 27
    
    print("\n--- STANDARD TIME (UTC-5) ---")
    dt_std_pre = datetime(2026, 1, 27, 8, 59, tzinfo=timezone.utc) # 03:59 ET
    dt_std_at  = datetime(2026, 1, 27, 9, 0, tzinfo=timezone.utc)  # 04:00 ET
    dt_std_post= datetime(2026, 1, 27, 9, 1, tzinfo=timezone.utc)  # 04:01 ET
    
    test_time(dt_std_pre, "STD PRE-RESET (03:59 ET)")
    test_time(dt_std_at,  "STD AT-RESET  (04:00 ET)")
    test_time(dt_std_post,"STD POST-RESET(04:01 ET)")

    # 2. Daylight Time (e.g., Jun 27 2026)
    # UTC-4. 04:00 ET = 08:00 UTC.
    # 03:59 ET = 07:59 UTC -> Should be Jun 26
    # 04:00 ET = 08:00 UTC -> Should be Jun 27
    
    print("\n--- DAYLIGHT TIME (UTC-4) ---")
    dt_dst_pre = datetime(2026, 6, 27, 7, 59, tzinfo=timezone.utc) # 03:59 ET
    dt_dst_at  = datetime(2026, 6, 27, 8, 0, tzinfo=timezone.utc)  # 04:00 ET
    dt_dst_post= datetime(2026, 6, 27, 8, 1, tzinfo=timezone.utc)  # 04:01 ET
    
    test_time(dt_dst_pre, "DST PRE-RESET (03:59 ET)")
    test_time(dt_dst_at,  "DST AT-RESET  (04:00 ET)")
    test_time(dt_dst_post,"DST POST-RESET(04:01 ET)")

    print("\n[+] Verification Complete.")

if __name__ == "__main__":
    main()
