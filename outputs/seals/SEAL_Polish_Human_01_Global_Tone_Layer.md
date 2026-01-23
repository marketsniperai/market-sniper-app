
# SEAL: Polish.Human.01 - Global Tone Layer

## 1. Summary
Implemented "Human Mode" as a global configuration layer. This toggle controls the tone of voice across the application, allowing users to switch between "Human-Friendly" (Explanatory) and "Institutional" (Concise/Machine) language.

## 2. Changes
- **Service**: `lib/services/human_mode_service.dart` manages state and persistence (default: ON).
- **Logic**: `lib/logic/tone.dart` provides `Tone.of(human: ..., machine: ...)` helper.
- **Wiring**: 
  - `main.dart`: Wrapped app in `ListenableBuilder` to trigger global rebuilds on mode change.
  - `menu_screen.dart`: Wired toggle switch to service.
- **Copy**: Applied tone branching to `RitualPreviewScreen` as a proof-of-concept.

## 3. Human Mode Definition
- **ON (Human)**: Warmer, full sentences, explains "Why".
  - *Example*: "This ritual provides institutional context..."
- **OFF (Machine)**: Cold, telegraphic, focuses on "What".
  - *Example*: "Ritual locked. Context required."

## 4. Verification
- **Compilation**: Passes `flutter analyze`.
- **Toggle**:
  - Toggling in Menu persists preference.
  - Shows SnackBar confirmation.
  - Global app rebuilds (observable by navigating to Preview).
- **UI Check**: 
  - Verified `RitualPreviewScreen` copy changes dynamically based on toggle.

## 5. Notes
- Future polish steps can inspect `HumanModeService().enabled` to adjust other copy areas (Tooltips, Error messages, Empty states).
