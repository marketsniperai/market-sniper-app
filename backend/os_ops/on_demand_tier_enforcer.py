import os
import json
import time
from datetime import datetime, timedelta, timezone
from typing import Tuple, Dict, Optional
from backend.artifacts.io import safe_read_or_fallback

# --- CONSTANTS ---
POLICY_FILE = "outputs/os/os_on_demand_tier_limits.json"
LEDGER_FILE = "outputs/os/on_demand_usage_ledger.jsonl"
DEFAULT_LIMITS = {
    "free_daily_limit": 3,
    "plus_daily_limit": 10,
    "elite_daily_limit": -1,
    "founder_daily_limit": -1
}

class OnDemandTierEnforcer:
    
    @staticmethod
    def _read_policy() -> Dict:
        res = safe_read_or_fallback(POLICY_FILE)
        if res["success"]:
            return res["data"]
        return {"limits": DEFAULT_LIMITS, "reset_config": {"reset_time_et": "04:00"}}

    @staticmethod
    def _get_start_of_us_dst(year: int) -> datetime:
        # 2nd Sunday in March
        # Quick calc: March 1st. 
        # weekday(): Mon=0, Sun=6.
        # If Mar 1 is Sun(6) -> +7 days = Mar 8 (2nd Sun)
        # If Mar 1 is Sat(5) -> 1st Sun is Mar 2 -> +7 = Mar 9.
        # offset = (6 - d.weekday() + 7) % 7 ? No.
        # first_sun_day = 1 + (6 - mar1.weekday() + 1) % 7? No.
        # Let's rely on dateutil or simple iteration if pure stdlib without complex helpers.
        # Actually, we have ZoneInfo now! We don't need manual DST math in Python.
        pass

    @staticmethod
    def _compute_bucket_for_dt(dt: datetime) -> str:
        """
        Pure logic helper.
        Input: datetime (aware or naive assumed UTC if naive, though strictly we want aware).
        Algo:
          1. Convert to America/New_York
          2. If Hour < 4: count as Previous Day
        """
        try:
            from zoneinfo import ZoneInfo
        except ImportError:
            # Fallback for very old generic python if absolute must, but we verified 3.14.
            from backports.zoneinfo import ZoneInfo
            
        tz_et = ZoneInfo("America/New_York")
        
        # Ensure dt is aware
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
            
        # Convert to ET
        dt_et = dt.astimezone(tz_et)
        
        # Reset Logic: 04:00 ET
        if dt_et.hour < 4:
            bucket_date = (dt_et - timedelta(days=1)).date()
        else:
            bucket_date = dt_et.date()
            
        return bucket_date.isoformat()

    @staticmethod
    def _get_current_bucket_et() -> str:
        """
        Calculates the 'Business Day' bucket for US/Eastern.
        Reset is 04:00 ET.
        If Usage Time < 04:00 ET, it belongs to Previous Day.
        """
        now_utc = datetime.now(timezone.utc)
        return OnDemandTierEnforcer._compute_bucket_for_dt(now_utc)
            
    @staticmethod
    def _count_usage_for_bucket(ticker: str, bucket: str, tier: str) -> int:
        if not os.path.exists(LEDGER_FILE):
             return 0
             
        count = 0
        # Scan Ledger (Reverse optimal, but simple scan implies bounded size if rotated)
        # We rotate ledgers, so file size shouldn't be massive.
        try:
            with open(LEDGER_FILE, 'r') as f:
                for line in f:
                    try:
                       entry = json.loads(line)
                       # Match Bucket and Tier
                       # We count PER USER (Tier based). 
                       # Wait, this system is single-user currently, but has "Tier" modes.
                       # So we count total usage for the "Current Tier Mode".
                       if entry.get("bucket") == bucket and entry.get("tier") == tier:
                           count += 1
                    except: pass
        except: pass
        return count

    @staticmethod
    def _log_usage(ticker: str, tier: str, bucket: str, founder_key: Optional[str]):
        entry = {
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "bucket": bucket,
            "tier": tier,
            "ticker": ticker,
            "founder_key_used": bool(founder_key)
        }
        
        try:
            with open(LEDGER_FILE, 'a') as f:
                f.write(json.dumps(entry) + "\n")
        except: pass

    @staticmethod
    def _check_cooldown(ticker: str, cooldown_seconds: int) -> Tuple[bool, int]:
        """
        Checks if the ticker is in cooldown for the current user/system context.
        Returns: (is_allowed, remaining_seconds)
        """
        if cooldown_seconds <= 0:
            return (True, 0)
            
        if not os.path.exists(LEDGER_FILE):
             return (True, 0)
             
        # Scan ledger for last usage of this ticker
        # We need the most recent entry for this ticker.
        # Since ledger is append-only, reading lines in reverse would be best, 
        # but for simplicity we read all and find max timestamp for ticker.
        
        last_ts = None
        now_utc = datetime.now(timezone.utc)
        
        try:
            with open(LEDGER_FILE, 'r') as f:
                for line in f:
                    try:
                       entry = json.loads(line)
                       if entry.get("ticker") == ticker:
                           ts_str = entry.get("timestamp_utc")
                           if ts_str:
                               ts = datetime.fromisoformat(ts_str)
                               # Basic timezone fix if ledger has naive or different format
                               if ts.tzinfo is None:
                                   ts = ts.replace(tzinfo=timezone.utc)
                                   
                               if last_ts is None or ts > last_ts:
                                   last_ts = ts
                    except: pass
        except: pass
        
        if last_ts:
            delta = (now_utc - last_ts).total_seconds()
            if delta < cooldown_seconds:
                return (False, int(cooldown_seconds - delta))
                
        return (True, 0)

    @staticmethod
    def check_and_log(ticker: str, tier: str, founder_key: Optional[str] = None) -> Tuple[bool, int, int, str, int]:
        """
        Returns: (allowed, current_count, limit, reason, cooldown_remaining)
        """
        policy = OnDemandTierEnforcer._read_policy()
        limits = policy.get("limits", DEFAULT_LIMITS)
        cooldowns = policy.get("cooldowns_seconds", {})
        
        # Founder Bypass hard check
        if founder_key and len(founder_key) > 0:
             active_tier = "FOUNDER" 
        else:
             active_tier = tier.upper()
             
        # Determine Limit
        limit = -1
        if active_tier == "FREE": limit = limits.get("free_daily_limit", 0)
        elif active_tier == "PLUS": limit = limits.get("plus_daily_limit", 10)
        elif active_tier == "ELITE": limit = limits.get("elite_daily_limit", -1)
        elif active_tier == "FOUNDER": limit = limits.get("founder_daily_limit", -1)
        
        # Determine Cooldown
        cooldown_sec = cooldowns.get(active_tier.lower(), 0)

        bucket = OnDemandTierEnforcer._get_current_bucket_et()
        
        # 1. Zero Limit Check (Blocked Tier)
        if limit == 0:
             return (False, 0, 0, "TIER_LOCKED", 0)

        # 2. Cooldown Check (if not Unlimited or even if Unlimited?)
        # Policy: "Elite: unlimited/day, cooldown 5m". So yes, check cooldown.
        is_cooldown_ok, remaining_sec = OnDemandTierEnforcer._check_cooldown(ticker, cooldown_sec)
        
        if not is_cooldown_ok:
             return (False, -1, limit, "COOLDOWN_ACTIVE", remaining_sec)
        
        # 3. Daily Limit Check
        # If unlimited
        if limit == -1:
            OnDemandTierEnforcer._log_usage(ticker, active_tier, bucket, founder_key)
            return (True, -1, -1, "UNLIMITED", 0)
            
        # Count
        current_count = OnDemandTierEnforcer._count_usage_for_bucket(ticker, bucket, active_tier)
        
        if current_count >= limit:
            return (False, current_count, limit, "LIMIT_REACHED", 0)
            
        # Log & Allow
        OnDemandTierEnforcer._log_usage(ticker, active_tier, bucket, founder_key)
        
        # Return count + 1 since we just logged
        return (True, current_count + 1, limit, "OK", 0)
