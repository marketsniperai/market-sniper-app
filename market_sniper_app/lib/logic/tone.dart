import '../services/human_mode_service.dart';

class Tone {
  /// Returns 'human' string if Human Mode is ON, else 'machine' (institutional) string.
  ///
  /// Usage:
  /// Text(Tone.of(human: "Hello friend.", machine: "System Ready."))
  static String of({required String human, required String machine}) {
    // Access singleton directly for simplicity in widgets.
    // For reactive rebuilds, the widget usually listens to the service
    // or we assume the build catches the change via AnimatedBuilder/MultiProvider if wired.
    // Ideally, screens should wrap themselves or specific texts in a listener.
    // But for V1 Polish, we'll check the current value.
    // *Caveat*: If the widget doesn't rebuild on toggle, this value won't update until next build.
    // We will ensure Menu triggers a rebuild or we use a ValueListenableBuilder where critical.
    if (HumanModeService().enabled) {
      return human;
    } else {
      return machine;
    }
  }
}
