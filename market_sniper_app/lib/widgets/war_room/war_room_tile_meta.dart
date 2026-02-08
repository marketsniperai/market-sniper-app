enum WarRoomDataOrigin { real, unavailable, simulated }

class WarRoomTileMeta {
  final String id;
  final String endpoint;
  final String fieldPath;
  final WarRoomDataOrigin origin;
  final int? httpStatus;
  
  const WarRoomTileMeta({
    required this.id,
    required this.endpoint,
    required this.fieldPath,
    this.origin = WarRoomDataOrigin.real,
    this.httpStatus,
  });
}

// Registry of Canonical Tiles
// DO NOT LIE. These must match actual wiring.
class WarRoomTileRegistry {
  static const osHealth = WarRoomTileMeta(
    id: "OS",
    endpoint: "/lab/os/health",
    fieldPath: "os_health.status",
  );

  static const autopilot = WarRoomTileMeta(
    id: "CTRL",
    endpoint: "/lab/os/self_heal/autofix/tier1/status", // Rewired from /lab/autofix/status
    fieldPath: "autofix.mode",
  );

  static const misfire = WarRoomTileMeta(
    id: "FIRE",
    endpoint: "/misfire",
    fieldPath: "misfire.status",
  );

  static const housekeeper = WarRoomTileMeta(
    id: "KEEP",
    endpoint: "/lab/os/self_heal/housekeeper/status",
    fieldPath: "housekeeper.result",
  );

  static const iron = WarRoomTileMeta(
    id: "IRON",
    endpoint: "/lab/os/iron/status",
    fieldPath: "iron.state",
  );

  static const replay = WarRoomTileMeta(
    id: "RPLY",
    endpoint: "/lab/os/iron/replay_integrity",
    fieldPath: "replay.valid",
  );
  
  static const universe = WarRoomTileMeta(
    id: "UNIV",
    endpoint: "/universe", // To be implemented
    fieldPath: "universe.status",
  );
  
  static const lkg = WarRoomTileMeta(
    id: "LKG",
    endpoint: "/lab/os/iron/lkg", // To be implemented
    fieldPath: "lkg.valid",
  );

  // Alpha Strip
  static const options = WarRoomTileMeta(
    id: "OPT",
    endpoint: "/options_context", // To be implemented or alias? NOTE: This wasn't in ghost report? 
    // Wait, options_context wasn't in ghost report because it might not have been hit or is valid?
    // Double check backend scan.
    fieldPath: "options.status",
  );

  static const evidence = WarRoomTileMeta(
    id: "EVID",
    endpoint: "/lab/evidence_summary", // To be implemented (Stub)
    fieldPath: "evidence.status",
  );
  
  static const macro = WarRoomTileMeta(
    id: "MACRO",
    endpoint: "/lab/macro_context", // To be implemented (Stub)
    fieldPath: "macro.status",
  );

  static const drift = WarRoomTileMeta(
    id: "DRIFT",
    endpoint: "/lab/os/iron/drift",
    fieldPath: "drift.status",
  );

  static const findings = WarRoomTileMeta(
    id: "FIND",
    endpoint: "/lab/war_room",
    fieldPath: "findings.findings",
  );
}
