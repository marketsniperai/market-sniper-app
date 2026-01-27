# SEAL: D45 SECTOR REPLAY V1.3

**Date:** 2026-01-25
**Author:** Antigravity (Agent)
**Status:** SEALED (PASS)
**Verification:** Web Build + Static Analysis + Discipline

## 1. Objective
Upgrade Sector Replay to V1.3 (Pulse SSOT): Prioritize dedicated Pulse artifact consumption (`outputs/pulse/sector_replay.json`) or existing API snapshots over synthetic data, with strict staleness guards.

## 2. Implementation
- **Prioritized Fetch:** 
  1. `outputs/pulse/sector_replay.json` (Dedicated Static)
  2. `/dashboard` (Legacy Real Data)
  3. Synthetic Fallback (V1.1 behavior)
- **Staleness Guard:** Frames older than 20 minutes are rejected (forcing fallback or next source).
- **Founder Visibility:** Added `SRC: PULSE` / `SRC: SYNTH` tag (visible only in Founder builds/Debug).
- **Sentinel:** Verified RT V0 events function seamlessly on V1.3 frames.

## 3. Verification
- **Web Build:** PASS.
- **Discipline:** PASS.
- **Runtime:** Verified fallback chain and visibility logic.

## 4. Manifest
- `market_sniper_app/lib/widgets/dashboard/sector_flip_widget_v1.dart`
- `outputs/proofs/polish/sector_replay_v1_3_proof.json`

## 5. Next Steps
- Ensure Pulse Job writes to `outputs/pulse/sector_replay.json`.
