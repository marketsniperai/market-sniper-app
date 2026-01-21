# SEAL: DAY 45.10 — SHARE PROMPT LOOP

## SUMMARY
D45.10 implements a deterministic **Share Prompt Loop** (Booster Sheet) that appears after a successful export, driving engagement and upgrades. The loop respects strict cooldowns, Tier limits, and Founder bypass rules.

## FEATURES
- **Share Prompt Loop Logic**: Centralized manager (`share_prompt_loop.dart`) enforcing 10m cooldown and logging.
- **Booster Sheet UI**: `ShareBoosterSheet` with "Save", "Share", and "Unlock Elite" CTAs.
- **Integration**: Wired into `ShareExporter` to trigger post-export.
- **Policy**: `outputs/os/os_share_prompt_loop_policy.json` governs behavior.
- **Telemetry**: Logs prompt lifecycle events to the Share Ledger.

## ARTIFACTS
- `market_sniper_app/lib/logic/share/share_prompt_loop.dart`
- `market_sniper_app/lib/widgets/share/share_booster_sheet.dart`
- `market_sniper_app/lib/logic/share/share_exporter.dart` (Modified)
- `market_sniper_app/lib/widgets/share_button.dart` (Modified)
- `market_sniper_app/lib/screens/share_library_screen.dart` (Modified)
- `outputs/os/os_share_prompt_loop_policy.json`

## PROOF
- `outputs/proofs/day_45/ui_share_prompt_loop_proof.json`

## STATUS
**SEALED**
