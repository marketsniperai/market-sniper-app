# HF29/HF33 Share Payload Note

**Context:** D47.HF33 Area Seal
**Topic:** Share Mini-Card Payload Safety

## Viral Safety Logic
The `ShareModal` generates a `MiniCard` widget which is inherently "Safe".
- **Visuals:** It uses `Stack` + `BackdropFilter` to blur text lines.
- **Data:** It displays TOP BULLET only (Intel Teaser), Ticker, and Reliability.
- **Exclusion:** It explicitly EXCLUDES the "Future Chart" and deep "Tactical Playbook".

## Payload Verification
When `ShareExporter.captureAndSave` is called:
1. `RepaintBoundary` captures the `MiniCardWidget`.
2. `MiniCardWidget` renders with hardcoded blurring logic (`_buildBlurredLine`).
3. Resulting PNG is a "Safe Artifact" suitable for viral distribution.
4. No PII or Premium Intel leaks.

**Status:** Verified via Code Inspection of `mini_card_widget.dart` and `share_modal.dart`.
