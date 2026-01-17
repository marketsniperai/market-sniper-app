import '../models/war_room_snapshot.dart';
import '../models/system_health_snapshot.dart';

enum WarRoomGlobalState {
  nominal,
  degraded,
  incident,
  unavailable
}

class WarRoomHealthEvaluation {
  final WarRoomGlobalState state;
  final String message;
  final List<String> issues;

  const WarRoomHealthEvaluation({
    required this.state,
    required this.message,
    required this.issues,
  });
  
  static const WarRoomHealthEvaluation loading = WarRoomHealthEvaluation(
    state: WarRoomGlobalState.nominal, 
    message: "Loading...", 
    issues: []
  );
}

class WarRoomDegradePolicy {
  static WarRoomHealthEvaluation evaluate(WarRoomSnapshot snapshot) {
    final issues = <String>[];
    WarRoomGlobalState state = WarRoomGlobalState.nominal;

    // 1. Availability Checks (Red)
    if (!snapshot.osHealth.status.toString().isNotEmpty || 
        !snapshot.misfire.isAvailable) {
      issues.add("Critical Telemetry Missing");
      state = WarRoomGlobalState.unavailable; // Partial availability is essentially unavailable for WR truth
    }
    
    // 2. Incident Checks (Red)
    if (snapshot.osHealth.status == HealthStatus.locked) {
      issues.add("OS LOCKED");
      state = WarRoomGlobalState.incident;
    }
    if (snapshot.misfire.status == "MISFIRE") {
      issues.add("Active Misfire");
      state = WarRoomGlobalState.incident;
    }
    
    // 3. Degraded Checks (Orange)
    if (state != WarRoomGlobalState.incident && state != WarRoomGlobalState.unavailable) {
      if (snapshot.osHealth.status == HealthStatus.degraded) {
        issues.add("OS Degraded");
        state = WarRoomGlobalState.degraded;
      }
      if (!snapshot.autopilot.isAvailable || snapshot.autopilot.mode == "UNAVAILABLE") {
         issues.add("Autopilot Offline");
         state = WarRoomGlobalState.degraded;
      }
      if (snapshot.housekeeper.result == "FAILED") {
         issues.add("Housekeeper Failed");
         state = WarRoomGlobalState.degraded;
      }

      if (snapshot.universe.status == "SIM") {
         issues.add("Universe is SIM");
         state = WarRoomGlobalState.degraded;
      }
    }
    
    // 4. Construct Message
    String message = "SYSTEM NOMINAL";
    if (state == WarRoomGlobalState.unavailable) {
      message = "TELEMETRY UNAVAILABLE";
    } else if (state == WarRoomGlobalState.incident) {
      message = "ACTIVE INCIDENT";
    } else if (state == WarRoomGlobalState.degraded) {
      message = "SYSTEM DEGRADED";
    }
    
    return WarRoomHealthEvaluation(
      state: state,
      message: message,
      issues: issues,
    );
  }
}
