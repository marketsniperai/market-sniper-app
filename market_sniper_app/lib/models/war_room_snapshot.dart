import 'system_health_snapshot.dart';

class WarRoomSnapshot {
  final SystemHealthSnapshot osHealth;
  final AutopilotSnapshot autopilot;
  final MisfireSnapshot misfire;
  final HousekeeperSnapshot housekeeper;
  final IronSnapshot iron;
  final IronTimelineSnapshot ironTimeline;
  final IronStateHistorySnapshot ironHistory;
  final LKGSnapshot lkg;
  final DecisionPathSnapshot decisionPath;
  final DriftSnapshot drift;
  final ReplayIntegritySnapshot replay;
  final LockReasonSnapshot lockReason;
  final CoverageSnapshot coverage;
  final UniverseSnapshot universe;
  final FindingsSnapshot findings;
  final BeforeAfterDiffSnapshot? beforeAfterDiff;


  const WarRoomSnapshot({
    required this.osHealth,
    required this.autopilot,
    required this.misfire,
    required this.housekeeper,
    required this.iron,
    required this.ironTimeline,
    required this.ironHistory,
    required this.lkg,
    required this.decisionPath,
    required this.drift,
    required this.replay,
    required this.lockReason,
    required this.coverage,
    required this.universe,
    required this.findings,
    this.beforeAfterDiff, // Nullable, as it might be missing
  });

  static const WarRoomSnapshot initial = WarRoomSnapshot(
    osHealth: SystemHealthSnapshot.unknown,
    autopilot: AutopilotSnapshot.unknown,
    misfire: MisfireSnapshot.unknown,
    housekeeper: HousekeeperSnapshot.unknown,
    iron: IronSnapshot.unknown,
    ironTimeline: IronTimelineSnapshot.unknown,
    ironHistory: IronStateHistorySnapshot.unknown,
    lkg: LKGSnapshot.unknown,
    decisionPath: DecisionPathSnapshot.unknown,
    drift: DriftSnapshot.unknown,
    replay: ReplayIntegritySnapshot.unknown,
    lockReason: LockReasonSnapshot.unknown,
    coverage: CoverageSnapshot.unknown,
    universe: UniverseSnapshot.unknown,
    findings: FindingsSnapshot.unknown,
    beforeAfterDiff: null,
  );
}

// ... existing code ...

// Sub-snapshots for each tile
class AutopilotSnapshot {
  // Control Plane Fields
  final String mode; // OFF / SHADOW / SAFE_AUTOPILOT / FULL_AUTOPILOT
  final String stage; // OBSERVE / RECOMMEND / EXECUTE
  final String lastAction;
  final String lastActionTime;
  final int cooldownRemaining;
  
  // Meta
  final String source;
  final bool isAvailable;

  const AutopilotSnapshot({
    required this.mode,
    required this.stage,
    required this.lastAction,
    required this.lastActionTime,
    required this.cooldownRemaining,
    required this.source,
    required this.isAvailable,
  });

  static const AutopilotSnapshot unknown = AutopilotSnapshot(
    mode: "UNKNOWN",
    stage: "BOOT",
    lastAction: "None",
    lastActionTime: "",
    cooldownRemaining: 0,
    source: "local",
    isAvailable: false,
  );
}

class MisfireSnapshot {
  final String status; // NOMINAL / MISFIRE / DEGRADED / LOCKED / UNAVAILABLE
  final String lastMisfire;
  final bool autoRecovery; // Is enabled
  final String recoveryState; // IDLE / RECOVERING / FAILED (if available)
  final String lastAction;
  final int cooldown;
  final String proof; // PRESENT / MISSING / UNAVAILABLE
  final String note;
  final String source;
  final bool isAvailable;

  const MisfireSnapshot({
    required this.status,
    required this.lastMisfire,
    required this.autoRecovery,
    required this.recoveryState,
    required this.lastAction,
    required this.cooldown,
    required this.proof,
    required this.note,
    required this.source,
    required this.isAvailable,
  });

  static const MisfireSnapshot unknown = MisfireSnapshot(
    status: "LOADING",
    lastMisfire: "--",
    autoRecovery: false,
    recoveryState: "UNKNOWN",
    lastAction: "None",
    cooldown: 0,
    proof: "N/A",
    note: "Initializing...",
    source: "local",
    isAvailable: false,
  );
}

class HousekeeperSnapshot {
  final bool autoRun;
  final String lastRun;
  final String result;
  final int cooldown;
  final String source;
  final bool isAvailable;

  const HousekeeperSnapshot({
    required this.autoRun,
    required this.lastRun,
    required this.result,
    required this.cooldown,
    required this.source,
    required this.isAvailable,
  });

  static const HousekeeperSnapshot unknown = HousekeeperSnapshot(
    autoRun: false,
    lastRun: "NEVER",
    result: "UNKNOWN",
    cooldown: 0,
    source: "local",
    isAvailable: false,
  );
}

class IronSnapshot {
  final String status; // NOMINAL / ROLLBACK / UNAVAILABLE (Availability status)
  final String state; // SENSE / DECIDE / ACT / IDLE
  final String lastTick;
  final int ageSeconds;
  final String source;
  final bool isAvailable;

  const IronSnapshot({
    required this.status,
    required this.state,
    required this.lastTick,
    required this.ageSeconds,
    required this.source,
    required this.isAvailable,
  });

  static const IronSnapshot unknown = IronSnapshot(
    status: "LOADING",
    state: "BOOT",
    lastTick: "N/A",
    ageSeconds: 0,
    source: "local",
    isAvailable: false,
  );
}

class UniverseSnapshot {
  final String status; // LIVE / SIM / PARTIAL / UNAVAILABLE
  final String core; // e.g. "CORE20"
  final String extended; // "ON" / "OFF"
  final String overlayState; // "LIVE" / "SIM" / "PARTIAL"
  final int overlayAge;
  final String source;
  final bool isAvailable;

  const UniverseSnapshot({
    required this.status,
    required this.core,
    required this.extended,
    required this.overlayState,
    required this.overlayAge,
    required this.source,
    required this.isAvailable,
  });

  static const UniverseSnapshot unknown = UniverseSnapshot(
    status: "LOADING",
    core: "...",
    extended: "...",
    overlayState: "...",
    overlayAge: 0,
    source: "local",
    isAvailable: false,
  );
}

class IronTimelineEvent {
  final String timestamp;
  final String type;
  final String source;
  final String summary;

  const IronTimelineEvent({
    required this.timestamp,
    required this.type,
    required this.source,
    required this.summary,
  });
}

class IronTimelineSnapshot {
  final List<IronTimelineEvent> events;
  final String source;
  final bool isAvailable;

  const IronTimelineSnapshot({
    required this.events,
    required this.source,
    required this.isAvailable,
  });

  static const IronTimelineSnapshot unknown = IronTimelineSnapshot(
    events: [],
    source: "local",
    isAvailable: false,
  );
}

class IronStateHistoryEntry {
  final String state;
  final String timestamp;
  final String source;

  const IronStateHistoryEntry({
    required this.state,
    required this.timestamp,
    required this.source,
  });
}

class IronStateHistorySnapshot {
  final List<IronStateHistoryEntry> history;
  final String source;
  final bool isAvailable;

  const IronStateHistorySnapshot({
    required this.history,
    required this.source,
    required this.isAvailable,
  });

  static const IronStateHistorySnapshot unknown = IronStateHistorySnapshot(
    history: [],
    source: "local",
    isAvailable: false,
  );
}

class LKGSnapshot {
  final String hash;
  final String timestamp;
  final int sizeBytes;
  final bool valid;
  final String source;
  final bool isAvailable;

  const LKGSnapshot({
    required this.hash,
    required this.timestamp,
    required this.sizeBytes,
    required this.valid,
    required this.source,
    required this.isAvailable,
  });

  static const LKGSnapshot unknown = LKGSnapshot(
    hash: "UNKNOWN",
    timestamp: "N/A",
    sizeBytes: 0,
    valid: false,
    source: "local",
    isAvailable: false,
  );
}


class DecisionPathSnapshot {
  final String timestamp;
  final String type;
  final String reason;
  final bool fallbackUsed;
  final String? actionTaken;
  final String source;
  final bool isAvailable;

  const DecisionPathSnapshot({
    required this.timestamp,
    required this.type,
    required this.reason,
    required this.fallbackUsed,
    required this.actionTaken,
    required this.source,
    required this.isAvailable,
  });

  static const DecisionPathSnapshot unknown = DecisionPathSnapshot(
    timestamp: "N/A",
    type: "UNKNOWN",
    reason: "None",
    fallbackUsed: false,
    actionTaken: null,
    source: "local",
    isAvailable: false,
  );
}

class DriftEntry {
  final String component;
  final String expected;
  final String observed;
  final String timestamp;

  const DriftEntry({
    required this.component,
    required this.expected,
    required this.observed,
    required this.timestamp,
  });
}

class DriftSnapshot {
  final List<DriftEntry> entries;
  final String source;
  final bool isAvailable;

  const DriftSnapshot({
    required this.entries,
    required this.source,
    required this.isAvailable,
  });

  static const DriftSnapshot unknown = DriftSnapshot(
    entries: [],
    source: "local",
    isAvailable: false,
  );
}

class ReplayIntegritySnapshot {
  final bool corrupted;
  final bool truncated;
  final bool outOfOrder;
  final bool duplicateEvents;
  final String timestamp;
  final String source;
  final bool isAvailable;

  const ReplayIntegritySnapshot({
    required this.corrupted,
    required this.truncated,
    required this.outOfOrder,
    required this.duplicateEvents,
    required this.timestamp,
    required this.source,
    required this.isAvailable,
  });

  static const ReplayIntegritySnapshot unknown = ReplayIntegritySnapshot(
    corrupted: false,
    truncated: false,
    outOfOrder: false,
    duplicateEvents: false,
    timestamp: "N/A",
    source: "local",
    isAvailable: false,
  );
}

class CoverageEntry {
  final String capability;
  final String status; // AVAILABLE | DEGRADED | UNAVAILABLE
  final String? reason;

  const CoverageEntry({
    required this.capability,
    required this.status,
    this.reason,
  });
}

class CoverageSnapshot {
  final List<CoverageEntry> entries;
  final String source;
  final bool isAvailable;

  const CoverageSnapshot({
    required this.entries,
    required this.source,
    required this.isAvailable,
  });

  static const CoverageSnapshot unknown = CoverageSnapshot(
    entries: [],
    source: "local",
    isAvailable: false,
  );
}

class LockReasonSnapshot {
  final String lockState; // NONE | DEGRADED | LOCKED
  final String reasonCode;
  final String description;
  final String module;
  final String timestamp;
  final bool isAvailable;

  const LockReasonSnapshot({
    required this.lockState,
    required this.reasonCode,
    required this.description,
    required this.module,
    required this.timestamp,
    required this.isAvailable,
  });

  static const LockReasonSnapshot unknown = LockReasonSnapshot(
    lockState: "NONE",
    reasonCode: "N/A",
    description: "N/A",
    module: "N/A",
    timestamp: "N/A",
    isAvailable: false,
  );
}

class FindingEntry {
  final String findingCode;
  final String severity; // INFO, WARN, ERROR
  final String message;
  final String? originatingModule;
  final String? timestampUtc;

  const FindingEntry({
    required this.findingCode,
    required this.severity,
    required this.message,
    this.originatingModule,
    this.timestampUtc,
  });

  factory FindingEntry.fromJson(Map<String, dynamic> json) {
    return FindingEntry(
      findingCode: json['finding_code'] ?? 'UNKNOWN',
      severity: json['severity'] ?? 'INFO',
      message: json['message'] ?? 'No message',
      originatingModule: json['originating_module'],
      timestampUtc: json['timestamp_utc'],
    );
  }
}

class FindingsSnapshot {
  final List<FindingEntry> findings;

  const FindingsSnapshot({required this.findings});

  factory FindingsSnapshot.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('findings')) {
      var list = json['findings'] as List;
      List<FindingEntry> findingsList = list.map((i) => FindingEntry.fromJson(i)).toList();
      return FindingsSnapshot(findings: findingsList);
    }
    return const FindingsSnapshot(findings: []);
  }

  static const FindingsSnapshot unknown = FindingsSnapshot(findings: []);
}

class BeforeAfterDiffSnapshot {
  final String timestampUtc;
  final String? operationId;
  final String? originatingModule;
  final Map<String, dynamic> beforeState;
  final Map<String, dynamic> afterState;
  final List<String>? changedKeys;

  const BeforeAfterDiffSnapshot({
    required this.timestampUtc,
    this.operationId,
    this.originatingModule,
    required this.beforeState,
    required this.afterState,
    this.changedKeys,
  });

  factory BeforeAfterDiffSnapshot.fromJson(Map<String, dynamic> json) {
    return BeforeAfterDiffSnapshot(
      timestampUtc: json['timestamp_utc'] ?? 'N/A',
      operationId: json['operation_id'],
      originatingModule: json['originating_module'],
      beforeState: json['before_state'] ?? {},
      afterState: json['after_state'] ?? {},
      changedKeys: json['changed_keys'] != null ? List<String>.from(json['changed_keys']) : null,
    );
  }

  static const BeforeAfterDiffSnapshot unknown = BeforeAfterDiffSnapshot(
    timestampUtc: "N/A",
    beforeState: {},
    afterState: {},
  );
}
