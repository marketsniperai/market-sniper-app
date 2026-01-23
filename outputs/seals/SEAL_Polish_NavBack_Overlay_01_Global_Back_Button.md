
# SEAL: Polish.NavBack.Overlay.01 - Global Back Arrow

## 1. Summary
Implemented a global, transparent back-arrow overlay that appears automatically whenever the navigation stack allows popping. This provides a consistent "Back" mechanism across the app without requiring each screen to implement a specific AppBar.

## 2. Changes
- **Widget**: `lib/widgets/global_back_overlay.dart`
  - `GlobalBackOverlayObserver`: Tracks `Navigator` push/pop events to update visibility.
  - `GlobalBackOverlay`: Renders a safe-area positioned `Stack` with the back button.
- **Main**: Wired into `MaterialApp` using `navigatorObservers` and `builder`.

## 3. Implementation Details
- **Visibility**: Controlled by `Navigator.canPop()`, checked on every route change.
- **Visuals**: 44x44 hitbox, Top-Left SafeArea, Cyan Chevron.
- **Routing**: Tapping the overlay calls `navigator.pop()`.

## 4. Verification
- **Compilation**: Passes `flutter analyze`.
- **Behavior**:
  - Root (Dashboard): Overlay hidden.
  - Pushed Screen (Settings/Menu): Overlay visible.
  - Tap: Pops screen correctly.
- **Safety**: Uses `Material` + `InkWell` for splash feedback but no container fill, preserving layout context.

## 5. Notes
- If a screen has its own Back Button (e.g. `Scaffold` implicit leading), this overlay will appear *over* or near it. In v1, this redundancy is acceptable for consistency, but typically `BackButton` in `AppBar` handles itself. Users can use either.
