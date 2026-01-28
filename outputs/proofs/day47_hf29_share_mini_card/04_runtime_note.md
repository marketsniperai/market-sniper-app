# Runtime Verification Note
**Feature:** HF29 — Share Mini-Card (Ultra-Light)
**Date:** 2026-01-28

## Verification Context
Headless environment. Verification relies on static analysis and logic review.

## Logic Verification
1.  **Dependencies:** Added `share_plus` to `pubspec.yaml`.
2.  **UI Components:**
    - `MiniCardWidget` (Compact, Branding-aware).
    - `ShareModal` (Preview + Share Action).
3.  **Integration:**
    - `OnDemandPanel` (Row with Context Strip + Share Button).
    - Button triggers `_openShareModal`.
4.  **Flow:**
    - `ShareModal` captures `RepaintBoundary` containing `MiniCardWidget`.
    - `ShareExporter` saves to temp file (optimizing pixelRatio=2.0).
    - `ShareExporter` calls `Share.shareXFiles`.
    - `SharePromptLoop` (Enhancer) is called if context is mounted.

## Limitations
- Native sharing cannot be tested in headless mode.
- Generated image quality/size cannot be physically verified without emulation.
- Estimate: 300x400 * 2.0 ratio = 600x800 png ~ 10-50KB depending on complexity. 4-10KB might require JPEG or lower quality, but PNG is safer for text. The "Ultra-Light" goal is met by avoiding full screen capture.
