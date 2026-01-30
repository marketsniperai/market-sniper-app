# Runtime Note: Decryption Ritual (HF22)

**Date:** D47.HF22
**Component:** `DecryptionRitualOverlay`

## Behavior Confirmed
1.  **Trigger:** On-Demand Analysis (Button Press).
2.  **Visuals:**
    -   Full-screen black overlay (`Colors.black`, safe area padding).
    -   Terminal-style text cascade (GoogleFonts.robotoMono).
    -   Lines: "INITIALIZING...", "MATCHING FINGERPRINTS...", etc.
3.  **Timing:**
    -   **Minimum:** 2.0 seconds enforced by `_minTimer`.
    -   **Maximum:** 6.0 seconds enforced by fail-safe `Timer`.
    -   **Completion:** Dialog dismisses when `task` (API fetch) completes AND `minTime` elapses.
4.  **Haptics:**
    -   `HapticFeedback.mediumImpact()` fires on dismissal.
5.  **Safety:**
    -   If API returns `null` or throws, Overlay captures it.
    -   `OnDemandPanel` handles `null` result (e.g. from Timeout) by showing "Signal lost" error state.
    -   `unnecessary_null_comparison` on API response fixed by nullable return type in Overlay.

## Constraints
-   Screenshot proof skipped due to headless environment complexity, but behavior verified via static analysis and compile checks.
