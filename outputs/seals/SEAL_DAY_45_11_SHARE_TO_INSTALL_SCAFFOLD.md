# SEAL: DAY 45.11 — SHARE-TO-INSTALL SCAFFOLD

## SUMMARY
D45.11 establishes the deterministic **Share-to-Install** identification system. It introduces a persistent local counter to generate unique Share IDs (`MSR-SHARE-YYYYMMDD-XXX`) and integrates them into the institutional watermark with a tasteful install hint ("Get the OS → MarketSniper AI"), strictly avoiding raw URLs.

## FEATURES
- **Share ID Service**: `ShareIdService` generates unique, day-scoped IDs.
- **Install Hint**: `WatermarkService` now renders the Install Hint and Share ID.
- **Policy**: `outputs/os/os_share_to_install_policy.json` defines formatting and enabling.
- **Ledger**: `outputs/os/os_share_install_ledger.jsonl` tracks ID generation.

## ARTIFACTS
- `market_sniper_app/lib/logic/share/share_id_service.dart` (New)
- `market_sniper_app/lib/logic/share/watermark_service.dart` (Modified)
- `market_sniper_app/lib/logic/share/share_composer.dart` (Modified)
- `outputs/os/os_share_to_install_policy.json` (New)
- `outputs/os/os_share_install_ledger.jsonl` (New)

## PROOF
- `outputs/proofs/day_45/ui_share_to_install_scaffold_proof.json`

## STATUS
**SEALED**
