import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The Layout Police Guard.
///
/// Intercepts Flutter errors in Founder Builds specifically to catch
/// layout violations defined in [docs/dev/LAYOUT_POLICE.md].
///
/// This is NON-BLOCKING and does not crash the app. It only logs advice.
class LayoutPoliceGuard {
  static void install({required bool enabled}) {
    if (!enabled) return;

    // Chain into existing error handler if present
    final originalOnError = FlutterError.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      _analyzeError(details);
      if (originalOnError != null) {
        originalOnError(details);
      } else {
        // Fallback to dumping to console if no other handler
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Also hook platform errors for async exceptions that might be layout related
    // though FlutterError.onError catches the main layout ones.
  }

  static void _analyzeError(FlutterErrorDetails details) {
    final exceptionStr = details.exception.toString();
    final String? context = details.context?.toString();

    bool violationDetected = false;
    String violationName = "UNKNOWN";
    String advice = "";

    // Heuristic A: RenderFlex Overflow
    if (exceptionStr.contains("RenderFlex overflowed")) {
      violationDetected = true;
      violationName = "NAKED COLUMN OVERFLOW (Rule #2)";
      advice =
          "Wrap the Column in a CanonicalScrollContainer or SingleChildScrollView.";
    }
    // Heuristic B: Unbounded Height
    else if (exceptionStr
        .contains("Vertical viewport was given unbounded height")) {
      violationDetected = true;
      violationName = "UNBOUNDED HEIGHT TRAP (Illegal Pattern #2)";
      advice =
          "A ScrollView (ListView/GridView) is inside a Column without Expanded/Flexible constraints.";
    }
    // Heuristic C: ParentDataWidget
    else if (exceptionStr.contains("Incorrect use of ParentDataWidget")) {
      violationDetected = true;
      violationName = "INVALID WIDGET HIERARCHY";
      advice = "Expanded/Flexible must be direct children of Row/Column/Flex.";
    }
    // Heuristic D: ScrollController missing
    else if (exceptionStr
        .contains("ScrollController not attached to any scroll views")) {
      violationDetected = true;
      violationName = "GHOST CONTROLLER";
      advice =
          "You created a ScrollController but didn't pass it to a ScrollView. Check DraggableScrollableSheet wiring.";
    }

    if (violationDetected) {
      _logViolation(violationName, advice, context);
    }
  }

  static void _logViolation(String name, String advice, String? context) {
    debugPrint("\n");
    debugPrint("╔════════════════════════════════════════════════════╗");
    debugPrint("║ 🚓 LAYOUT POLICE VIOLATION DETECTED 🚓            ║");
    debugPrint("╠════════════════════════════════════════════════════╣");
    debugPrint("║ VIOLATION: $name");
    if (context != null) debugPrint("║ CONTEXT:   $context");
    debugPrint("║ ADVICE:    $advice");
    debugPrint("║ REFERENCE: docs/dev/LAYOUT_POLICE.md           ║");
    debugPrint("╚════════════════════════════════════════════════════╝");
    debugPrint("\n");
  }

  /// Helper to check Sheet Controller wiring explicitly
  static void noteSheetControllerWiring(
      {required String sheetName, required bool usesProvidedController}) {
    if (!usesProvidedController) {
      _logViolation(
          "SHEET CONTROLLER DISCONNECT (Rule #4)",
          "The sheet '$sheetName' is not using the provided DraggableScrollableSheet controller. Dragging will be broken.",
          "Sheet Check");
    }
  }
}
