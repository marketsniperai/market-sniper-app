import unittest
import datetime
import json
import os
import sys

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), '../../backend'))

from os_ops.elite_ritual_policy import EliteRitualPolicy

class TestEliteRitualPolicy(unittest.TestCase):
    def setUp(self):
        self.policy = EliteRitualPolicy()

    def test_morning_briefing_window(self):
        # Weekday 9:30 AM ET (Inside 9:20-9:50)
        dt = datetime.datetime(2026, 1, 29, 9, 30, 0, tzinfo=datetime.timezone.utc) 
        # CAREFUL: 9:30 UTC is NOT 9:30 ET.
        # 9:30 ET = 14:30 UTC (Standard)
        
        # Construct ET time directly to be sure, then convert to UTC for input
        et_tz = datetime.timezone(datetime.timedelta(hours=-5)) # EST
        dt_et = datetime.datetime(2026, 1, 29, 9, 30, 0, tzinfo=et_tz)
        dt_utc = dt_et.astimezone(datetime.timezone.utc)
        
        state = self.policy.get_ritual_state(dt_utc)
        self.assertTrue(state['morning_briefing']['enabled'])
        self.assertTrue(state['morning_briefing']['visible'])

    def test_sunday_setup_open(self):
        # Sunday 8:30 PM ET (Inside 20:00 Sun - 09:00 Mon)
        et_tz = datetime.timezone(datetime.timedelta(hours=-5))
        dt_et = datetime.datetime(2026, 1, 25, 20, 30, 0, tzinfo=et_tz) # Jan 25 2026 is Sunday
        dt_utc = dt_et.astimezone(datetime.timezone.utc)
        
        state = self.policy.get_ritual_state(dt_utc)
        self.assertTrue(state['sunday_setup']['enabled'])
        self.assertTrue(state['sunday_setup']['visible'])

    def test_sunday_setup_monday_morning(self):
        # Monday 8:30 AM ET (Inside)
        et_tz = datetime.timezone(datetime.timedelta(hours=-5))
        dt_et = datetime.datetime(2026, 1, 26, 8, 30, 0, tzinfo=et_tz) # Jan 26 is Monday
        dt_utc = dt_et.astimezone(datetime.timezone.utc)
        
        state = self.policy.get_ritual_state(dt_utc)
        self.assertTrue(state['sunday_setup']['enabled'])
        self.assertTrue(state['sunday_setup']['visible'])
        self.assertEqual(state['sunday_setup']['countdown_minutes'], 30) # 8:30 to 9:00 is 30m

    def test_sunday_setup_closed(self):
        # Monday 9:01 AM ET (Outside)
        et_tz = datetime.timezone(datetime.timedelta(hours=-5))
        dt_et = datetime.datetime(2026, 1, 26, 9, 1, 0, tzinfo=et_tz)
        dt_utc = dt_et.astimezone(datetime.timezone.utc)
        
        state = self.policy.get_ritual_state(dt_utc)
        self.assertFalse(state['sunday_setup']['enabled'])
        self.assertFalse(state['sunday_setup']['visible'])

    def generate_samples(self):
        self.setUp()
        samples = {}
        et_tz = datetime.timezone(datetime.timedelta(hours=-5))
        
        scenarios = {
            "Weekday_Morning_Open": datetime.datetime(2026, 1, 29, 9, 30, tzinfo=et_tz),
            "Weekday_Noon_Open": datetime.datetime(2026, 1, 29, 12, 45, tzinfo=et_tz),
            "Weekday_Closed_Night": datetime.datetime(2026, 1, 29, 23, 0, tzinfo=et_tz),
            "Sunday_Night_Setup": datetime.datetime(2026, 1, 25, 21, 0, tzinfo=et_tz),
            "Monday_Morning_Countdown": datetime.datetime(2026, 1, 26, 8, 55, tzinfo=et_tz)
        }
        
        for name, dt_et in scenarios.items():
            dt_utc = dt_et.astimezone(datetime.timezone.utc)
            samples[name] = {
                "timestamp_et": str(dt_et),
                "state": self.policy.get_ritual_state(dt_utc)
            }
            
        out_path = os.path.join(os.path.dirname(__file__), '../../outputs/samples/elite_ritual_policy_states.json')
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, 'w') as f:
            json.dump(samples, f, indent=2)
        print(f"Generated samples at {out_path}")

if __name__ == '__main__':
    # Run tests
    unittest.main(exit=False)
    # Generate samples
    TestEliteRitualPolicy().generate_samples()
