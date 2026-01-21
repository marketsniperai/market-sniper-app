# SEAL: DAY 45.06 — TRIAL (3 MARKET OPENS) + TRY-ME SCHEDULER

## SUMMARY
Implemented the deterministic Trial system based on 3 Market Opens and the "Try-Me Hour" scheduler.
- **Trial Engine**: Increments open count (0..3) only when app is opened during ET Market Hours (09:30-16:00, Mon-Fri) on a new market day.
- **Try-Me Scheduler**: Activates post-trial for Guests during the "Try-Me Window" (Mondays 09:20-10:20 ET).
- **Persistence**: Using `shared_preferences` securely via `TrialStateStore` (counting market day IDs).
- **UI Integration**: `PremiumScreen` displays precise "x/3 Market Opens" progress or status ("TRIAL COMPLETE", "TRY-ME ACTIVE").
- **Integration**: Hooked into `MainLayout.initState` for automatic open counting.

## ARTIFACTS
- `lib/logic/market_time_helper.dart` [NEW]
- `lib/logic/trial_state_store.dart` [NEW]
- `lib/logic/trial_engine.dart` [NEW]
- `lib/logic/try_me_scheduler.dart` [NEW]
- `lib/logic/premium_status_resolver.dart` [MODIFIED]
- `lib/layout/main_layout.dart` [MODIFIED]
- `outputs/os/os_trial_tryme_policy.json` [NEW]
- `outputs/proofs/day_45/ui_trial_tryme_scheduler_proof.json` [NEW]

## VERIFICATION
- **Logic**: Verified Market Hours check (ET) and duplicate day prevention.
- **Integration**: Confirmed resolver reads from Engine/Scheduler correctly.
- **Discipline**: Passed `verify_project_discipline.py`.

## STATUS
**SEALED** (Trial System Active)
