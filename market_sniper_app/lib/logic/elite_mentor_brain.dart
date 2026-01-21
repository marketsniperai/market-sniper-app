enum EliteToneMode { institutional, human }

class EliteMentorBrain {
  static final EliteMentorBrain _instance = EliteMentorBrain._internal();
  factory EliteMentorBrain() => _instance;
  EliteMentorBrain._internal();

  /// Current tone mode. 
  /// In a full implementation, this would read from user settings.
  /// For now, defaults to Institutional as per governance.
  EliteToneMode get toneMode => EliteToneMode.institutional;

  String getGreeting(String timeOfDay, String userName) {
    switch (toneMode) {
      case EliteToneMode.human:
        return "Good $timeOfDay, $userName. Let's map the market.";
      case EliteToneMode.institutional:
      default:
        // Precise. No emotion. Context over personality.
        return "System ready. Context engine active.";
    }
  }

  String formatHeader(String text) {
    switch (toneMode) {
      case EliteToneMode.human:
        // Title Case, friendly
        return text; 
      case EliteToneMode.institutional:
      default:
        // Uppercase, technical, spaced
        return text.toUpperCase();
    }
  }
  
  String formatSectionTitle(String text) {
    switch (toneMode) {
      case EliteToneMode.human:
         return text;
      case EliteToneMode.institutional:
      default:
         return text.toUpperCase();
    }
  }

  String get boundaryLine {
    switch (toneMode) {
      case EliteToneMode.human:
        return "Standby...";
      case EliteToneMode.institutional:
      default:
        return "[ END TRANSMISSION ]";
    }
  }
  
  String get explainLoadingStatus {
     switch (toneMode) {
      case EliteToneMode.human:
        return "Thinking...";
      case EliteToneMode.institutional:
      default:
        return "ANALYZING CONTEXT...";
    }
  }
  
  String get explainReadyStatus {
     switch (toneMode) {
      case EliteToneMode.human:
        return "Ready.";
      case EliteToneMode.institutional:
      default:
        return "CONTEXT EXPLAINED";
    }
  }
}
