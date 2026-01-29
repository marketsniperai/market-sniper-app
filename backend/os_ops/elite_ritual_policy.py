import json
import os
import datetime
import pytz

class EliteRitualPolicy:
    """
    Deterministic policy engine for Elite Rituals.
    Reads docs/canon/os_elite_ritual_policy_v1.json
    Evaluates availability, visibility, and countdowns based on US/Eastern time.
    """

    POLICY_PATH = os.path.join(os.path.dirname(__file__), '../../docs/canon/os_elite_ritual_policy_v1.json')
    TZ_EASTERN = pytz.timezone('US/Eastern')

    def __init__(self):
        self.policy = self._load_policy()

    def _load_policy(self):
        if not os.path.exists(self.POLICY_PATH):
            print(f"DEBUG: Policy path not found: {self.POLICY_PATH}")
            raise FileNotFoundError(f"Canonical policy not found at {self.POLICY_PATH}")
        print(f"DEBUG: Loading policy from {self.POLICY_PATH}")
        with open(self.POLICY_PATH, 'r') as f:
            return json.load(f)

    def get_ritual_state(self, now_utc: datetime.datetime) -> dict:
        """
        Returns the state of all rituals for the given UTC timestamp.
        """
        now_et = now_utc.astimezone(self.TZ_EASTERN)
        results = {}

        for ritual in self.policy['rituals']:
            rid = ritual['id']
            schedule = ritual['schedule']
            visibility_rule = ritual.get('visibility', 'always_visible')
            
            is_in_window = False
            countdown = None
            
            if schedule['type'] == 'daily_start_time':
                is_in_window = self._check_daily_window(now_et, schedule['start_time'], schedule['end_time'])
            
            elif schedule['type'] == 'weekly_window':
                is_in_window, countdown = self._check_weekly_window(
                    now_et, 
                    schedule['start_day'], schedule['start_time'],
                    schedule['end_day'], schedule['end_time'],
                    ritual.get('countdown_trigger_minutes')
                )

            # Determine Visibility
            visible = True
            if visibility_rule == 'window_only':
                visible = is_in_window

            # Determine Enabled
            enabled = is_in_window # Simplification: if enabled_rule is 'in_window', it matches.

            results[rid] = {
                "enabled": enabled,
                "visible": visible,
                "countdown_minutes": countdown
            }

        return results

    def _check_daily_window(self, now_et, start_str, end_str):
        # Parse HH:MM
        current_time = now_et.time()
        start = datetime.datetime.strptime(start_str, "%H:%M").time()
        end = datetime.datetime.strptime(end_str, "%H:%M").time()
        
        # Simple daily window (assuming no midnight crossing for daily rituals in this policy)
        if start <= end:
            return start <= current_time <= end
        else:
            # Crosses midnight (not expected for daily briefings but safer to handle)
            return current_time >= start or current_time <= end

    def _check_weekly_window(self, now_et, start_day_str, start_time_str, end_day_str, end_time_str, countdown_trigger):
        # Weekdays: Monday=0, Sunday=6
        weekdays = {
            "Monday": 0, "Tuesday": 1, "Wednesday": 2, "Thursday": 3,
            "Friday": 4, "Saturday": 5, "Sunday": 6
        }
        
        start_dow = weekdays[start_day_str]
        end_dow = weekdays[end_day_str]
        
        current_dow = now_et.weekday()
        
        # We need to construct absolute datetimes for the *current* occurrence of this window relative to now_et
        # This is tricky because "Sunday Setup" wraps locally around the weekend.
        
        # Strategy: Find recent start time check if we are between start and end.
        
        # Get start datetime on the most recent 'start_day'
        # Days since start day
        days_since_start = (current_dow - start_dow) % 7
        # Note: if it's currently start_day, days_since_start is 0.
        
        # Candidate start is 'days_since_start' days ago
        # BUT we must handle time. If it's start_day but BEFORE start_time, then the actual start was last week (7 days ago).
        
        candidate_start_date = now_et.date() - datetime.timedelta(days=days_since_start)
        start_time_obj = datetime.datetime.strptime(start_time_str, "%H:%M").time()
        
        start_dt = self.TZ_EASTERN.localize(datetime.datetime.combine(candidate_start_date, start_time_obj))
        
        # If now is before start_dt on the same day (e.g. Sunday morning vs Sunday night start), 
        # then the "active window" must have started last week.
        if days_since_start == 0 and now_et < start_dt:
             start_dt -= datetime.timedelta(days=7)

        # Calculate End DT relative to Start DT
        # Days delta between start and end
        # e.g. Sunday(6) -> Monday(0) = (0-6)%7 = 1 day
        days_duration = (end_dow - start_dow) % 7
        if days_duration == 0 and end_time_str <= start_time_str:
             days_duration = 1 # Assuming at least next day if times inverted, though mostly used for different days.
             
        end_time_obj = datetime.datetime.strptime(end_time_str, "%H:%M").time()
        end_dt = start_dt + datetime.timedelta(days=days_duration)
        # Adjust end_dt time component
        end_dt = end_dt.replace(hour=end_time_obj.hour, minute=end_time_obj.minute, second=0, microsecond=0)
        
        # Check window
        is_in = start_dt <= now_et <= end_dt
        
        countdown = None
        if is_in and countdown_trigger:
            remaining = (end_dt - now_et).total_seconds() / 60
            if 0 < remaining <= countdown_trigger:
                countdown = int(remaining)
                
        return is_in, countdown

if __name__ == "__main__":
    # Smoke Test
    policy = EliteRitualPolicy()
    now = datetime.datetime.now(datetime.timezone.utc)
    print(json.dumps(policy.get_ritual_state(now), indent=2))
