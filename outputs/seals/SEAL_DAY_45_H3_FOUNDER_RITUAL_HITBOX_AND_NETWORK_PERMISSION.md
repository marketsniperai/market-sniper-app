# SEAL: DAY 45.H3 — FOUNDER RITUAL HITBOX + NETWORK PERMISSION

## SUMMARY
Resolved critical usability blockers for physical devices:
1. **Network Permissions**: Added `INTERNET` and `ACCESS_NETWORK_STATE` to `AndroidManifest.xml` (Fixes `SocketException` on release builds).
2. **Ritual Hitbox**: Rewrote `MainLayout` ritual trigger to be a top-level, opaque, min-sized (48px) Container, ensuring 4/5-tap sequences are not swallowed by nested widgets or overlaps.

## ARTIFACTS
- **APK**: `market_sniper_founder_full_release.apk`
- **Destination**: `C:\Users\Sergio B\OneDrive\Desktop\Apk Release\`
- **SHA256**: `24F...` (Verified)
- **Git Head**: `0836271` (Clean)

## PROOFS
- `outputs/proofs/day_45/android_internet_permission_proof.json`
- `outputs/proofs/day_45/ui_founder_ritual_hitbox_no_overlap_proof.json`
- `outputs/proofs/day_45/ui_full_founder_h3_build_proof.json`

## STATUS
**SEALED**
