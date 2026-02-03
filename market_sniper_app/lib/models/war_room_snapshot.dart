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
  final AutoFixTier1Snapshot autofixTier1;
  final AutoFixDecisionPathSnapshot autofixDecisionPath;
  final MisfireRootCauseSnapshot misfireRootCause;
  final SelfHealConfidenceSnapshot selfHealConfidence;
  final SelfHealWhatChangedSnapshot selfHealWhatChanged;
  final CooldownTransparencySnapshot cooldownTransparency;
  final RedButtonStatusSnapshot redButton;
  final MisfireTier2Snapshot misfireTier2;
  final OptionsInfoSnapshot options; // D36.3
  final MacroInfoSnapshot macro; // D36.5
  final EvidenceInfoSnapshot evidence; // D36.4
  final int? warRoomHttpStatus; // D53.6A Truth Proof

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
    required this.autofixTier1,
    required this.autofixDecisionPath,
    required this.misfireRootCause,
    required this.selfHealConfidence,
    required this.selfHealWhatChanged,
    required this.cooldownTransparency,
    required this.redButton,
    required this.misfireTier2,
    required this.options, // D36.3
    required this.macro, // D36.5
    required this.evidence, // D36.4
    this.warRoomHttpStatus,
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
    autofixTier1: AutoFixTier1Snapshot.unknown,
    autofixDecisionPath: AutoFixDecisionPathSnapshot.unknown,
    misfireRootCause: MisfireRootCauseSnapshot.unknown,
    selfHealConfidence: SelfHealConfidenceSnapshot.unknown,
    selfHealWhatChanged: SelfHealWhatChangedSnapshot.unknown,
    cooldownTransparency: CooldownTransparencySnapshot.unknown,
    redButton: RedButtonStatusSnapshot.unknown,
    misfireTier2: MisfireTier2Snapshot.unknown,
    options: OptionsInfoSnapshot.unknown, // D36.3
    macro: MacroInfoSnapshot.unknown, // D36.5
    evidence: EvidenceInfoSnapshot.unknown, // D36.4
  );
}

class OptionsInfoSnapshot {
  final String status;
  final String coverage;
  final String ivRegime;
  final String skew;
  final String expectedMove;
  final String asOfUtc;
  final bool isAvailable;

  // v1.1.0 Fields
  final String version;
  final String expectedMoveHorizon;
  final String confidence;
  final String note;
  // Diagnostics
  final bool providerAttempted;
  final String providerResult;
  final String fallbackReason;

  const OptionsInfoSnapshot({
    required this.status,
    required this.coverage,
    required this.ivRegime,
    required this.skew,
    required this.expectedMove,
    required this.asOfUtc,
    required this.isAvailable,
    required this.version,
    required this.expectedMoveHorizon,
    required this.confidence,
    required this.note,
    required this.providerAttempted,
    required this.providerResult,
    required this.fallbackReason,
  });

  static const OptionsInfoSnapshot unknown = OptionsInfoSnapshot(
    status: "N_A",
    coverage: "N_A",
    ivRegime: "N/A",
    skew: "N/A",
    expectedMove: "N/A",
    asOfUtc: "N/A",
    isAvailable: false,
    version: "1.0",
    expectedMoveHorizon: "N/A",
    confidence: "N_A",
    note: "",
    providerAttempted: false,
    providerResult: "NONE",
    fallbackReason: "INIT",
  );
}

class MisfireTier2Snapshot {
  final String timestampUtc;
  final String incidentId;
  final String detectedBy;
  final String escalationPolicy;
  final List<MisfireEscalationStepSnapshot> steps;
  final String finalOutcome;
  final String? actionTaken;
  final String? notes;
  final bool isAvailable;

  const MisfireTier2Snapshot({
    required this.timestampUtc,
    required this.incidentId,
    required this.detectedBy,
    required this.escalationPolicy,
    required this.steps,
    required this.finalOutcome,
    this.actionTaken,
    this.notes,
    required this.isAvailable,
  });

  static const MisfireTier2Snapshot unknown = MisfireTier2Snapshot(
    timestampUtc: "N/A",
    incidentId: "N/A",
    detectedBy: "N/A",
    escalationPolicy: "N/A",
    steps: [],
    finalOutcome: "N/A",
    isAvailable: false,
  );
}

class MisfireEscalationStepSnapshot {
  final String stepId;
  final String description;
  final bool attempted;
  final bool permitted;
  final String? gateReason;
  final String? result;
  final String? timestampUtc;

  const MisfireEscalationStepSnapshot({
    required this.stepId,
    required this.description,
    required this.attempted,
    required this.permitted,
    this.gateReason,
    this.result,
    this.timestampUtc,
  });
}

class MacroInfoSnapshot {
  final String status;
  final String coverage;
  final String rates;
  final String dollar;
  final String oil;
  final String summary;
  final bool isAvailable;

  const MacroInfoSnapshot({
    required this.status,
    required this.coverage,
    required this.rates,
    required this.dollar,
    required this.oil,
    required this.summary,
    required this.isAvailable,
  });

  static const MacroInfoSnapshot unknown = MacroInfoSnapshot(
    status: "N_A",
    coverage: "N_A",
    rates: "N/A",
    dollar: "N/A",
    oil: "N/A",
    summary: "Initializing...",
    isAvailable: false,
  );
}

class EvidenceInfoSnapshot {
  final String status;
  final int sampleSize;
  final String headline;
  final bool isAvailable;

  const EvidenceInfoSnapshot({
    required this.status,
    required this.sampleSize,
    required this.headline,
    required this.isAvailable,
  });

  static const EvidenceInfoSnapshot unknown = EvidenceInfoSnapshot(
    status: "N_A",
    sampleSize: 0,
    headline: "Initializing...",
    isAvailable: false,
  );
}

class RedButtonStatusSnapshot {
  final String timestampUtc;
  final bool available;
  final bool founderRequired;
  final List<String> capabilities;
  final RedButtonRunSummarySnapshot? lastRun;

  const RedButtonStatusSnapshot({
    required this.timestampUtc,
    required this.available,
    required this.founderRequired,
    required this.capabilities,
    this.lastRun,
  });

  static const RedButtonStatusSnapshot unknown = RedButtonStatusSnapshot(
    timestampUtc: "N/A",
    available: false,
    founderRequired: true,
    capabilities: [],
  );
}

class RedButtonRunSummarySnapshot {
  final String runId;
  final String action;
  final String timestampUtc;
  final String status;
  final String? notes;

  const RedButtonRunSummarySnapshot({
    required this.runId,
    required this.action,
    required this.timestampUtc,
    required this.status,
    this.notes,
  });
}

class CooldownTransparencySnapshot {
  final String timestampUtc;
  final String? runId;
  final List<CooldownEntrySnapshot> entries;
  final bool isAvailable;

  const CooldownTransparencySnapshot({
    required this.timestampUtc,
    this.runId,
    required this.entries,
    required this.isAvailable,
  });

  static const CooldownTransparencySnapshot unknown =
      CooldownTransparencySnapshot(
    timestampUtc: "N/A",
    runId: "N/A",
    entries: [],
    isAvailable: false,
  );
}

class CooldownEntrySnapshot {
  final String engine;
  final String actionCode;
  final bool attempted;
  final bool permitted;
  final String gateReason;
  final int? cooldownRemainingSeconds;
  final int? throttleWindowSeconds;
  final String? lastExecutedTimestampUtc;
  final String? notes;

  const CooldownEntrySnapshot({
    required this.engine,
    required this.actionCode,
    required this.attempted,
    required this.permitted,
    required this.gateReason,
    this.cooldownRemainingSeconds,
    this.throttleWindowSeconds,
    this.lastExecutedTimestampUtc,
    this.notes,
  });
}

class SelfHealWhatChangedSnapshot {
  final String timestampUtc;
  final String runId;
  final String? summary;
  final List<ArtifactUpdateSnapshot> artifactsUpdated;
  final StateTransitionSnapshot? stateTransition;
  final bool isAvailable;

  const SelfHealWhatChangedSnapshot({
    required this.timestampUtc,
    required this.runId,
    this.summary,
    required this.artifactsUpdated,
    this.stateTransition,
    required this.isAvailable,
  });

  static const SelfHealWhatChangedSnapshot unknown =
      SelfHealWhatChangedSnapshot(
    timestampUtc: "N/A",
    runId: "N/A",
    artifactsUpdated: [],
    isAvailable: false,
  );
}

class ArtifactUpdateSnapshot {
  final String path;
  final String changeType;
  final String? beforeHash;
  final String? afterHash;

  const ArtifactUpdateSnapshot({
    required this.path,
    required this.changeType,
    this.beforeHash,
    this.afterHash,
  });
}

class StateTransitionSnapshot {
  final String? fromState;
  final String? toState;
  final bool unlocked;

  const StateTransitionSnapshot({
    this.fromState,
    this.toState,
    required this.unlocked,
  });
}

class SelfHealConfidenceSnapshot {
  final String timestampUtc;
  final String runId;
  final String overall;
  final List<ConfidenceEntrySnapshot> entries;
  final bool isAvailable;

  const SelfHealConfidenceSnapshot({
    required this.timestampUtc,
    required this.runId,
    required this.overall,
    required this.entries,
    required this.isAvailable,
  });

  static const SelfHealConfidenceSnapshot unknown = SelfHealConfidenceSnapshot(
    timestampUtc: "N/A",
    runId: "N/A",
    overall: "UNAVAILABLE",
    entries: [],
    isAvailable: false,
  );
}

class ConfidenceEntrySnapshot {
  final String engine;
  final String actionCode;
  final String confidence;
  final List<String> evidence;

  const ConfidenceEntrySnapshot({
    required this.engine,
    required this.actionCode,
    required this.confidence,
    required this.evidence,
  });
}

class MisfireRootCauseSnapshot {
  final String timestampUtc;
  final String incidentId;
  final String misfireType;
  final String originatingModule;
  final String detectedBy;
  final String? primaryArtifact;
  final String? pipelineMode;
  final String? fallbackUsed;
  final String? actionTaken;
  final String outcome;
  final String? notes;
  final bool isAvailable;

  const MisfireRootCauseSnapshot({
    required this.timestampUtc,
    required this.incidentId,
    required this.misfireType,
    required this.originatingModule,
    required this.detectedBy,
    this.primaryArtifact,
    this.pipelineMode,
    this.fallbackUsed,
    this.actionTaken,
    required this.outcome,
    this.notes,
    required this.isAvailable,
  });

  static const MisfireRootCauseSnapshot unknown = MisfireRootCauseSnapshot(
    timestampUtc: "N/A",
    incidentId: "N/A",
    misfireType: "UNKNOWN",
    originatingModule: "UNKNOWN",
    detectedBy: "UNKNOWN",
    outcome: "UNAVAILABLE",
    isAvailable: false,
  );
}

class AutoFixDecisionPathSnapshot {
  final String status;
  final String runId;
  final String context;
  final int actionCount;
  final List<DecisionActionSnapshot> actions;
  final bool isAvailable;

  const AutoFixDecisionPathSnapshot({
    required this.status,
    required this.runId,
    required this.context,
    required this.actionCount,
    required this.actions,
    required this.isAvailable,
  });

  static const AutoFixDecisionPathSnapshot unknown =
      AutoFixDecisionPathSnapshot(
    status: "UNAVAILABLE",
    runId: "N/A",
    context: "N/A",
    actionCount: 0,
    actions: [],
    isAvailable: false,
  );
}

class DecisionActionSnapshot {
  final String code;
  final String outcome;
  final String reason;

  const DecisionActionSnapshot({
    required this.code,
    required this.outcome,
    required this.reason,
  });
}

class AutoFixTier1Snapshot {
  final String status; // NOOP, SUCCESS, PARTIAL, FAILED, UNAVAILABLE
  final String planId;
  final int actionsExecuted;
  final String lastRun;
  final bool isAvailable;

  const AutoFixTier1Snapshot({
    required this.status,
    required this.planId,
    required this.actionsExecuted,
    required this.lastRun,
    required this.isAvailable,
  });

  static const AutoFixTier1Snapshot unknown = AutoFixTier1Snapshot(
    status: "UNAVAILABLE",
    planId: "N/A",
    actionsExecuted: 0,
    lastRun: "NEVER",
    isAvailable: false,
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
  final String timestampUtc; // Added for D53.3D Proof of Life
  final bool isAvailable;

  const UniverseSnapshot({
    required this.status,
    required this.core,
    required this.extended,
    required this.overlayState,
    required this.overlayAge,
    required this.source,
    required this.timestampUtc,
    required this.isAvailable,
  });

  static const UniverseSnapshot unknown = UniverseSnapshot(
    status: "LOADING",
    core: "...",
    extended: "...",
    overlayState: "...",
    overlayAge: 0,
    source: "local",
    timestampUtc: "N/A",
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
  final String status;
  final String assetSkew;
  final int systemClockOffsetMs;
  final List<DriftEntry> entries;
  final String source;
  final bool isAvailable;

  const DriftSnapshot({
    required this.status,
    required this.assetSkew,
    required this.systemClockOffsetMs,
    required this.entries,
    required this.source,
    required this.isAvailable,
  });

  static const DriftSnapshot unknown = DriftSnapshot(
    status: "N/A",
    assetSkew: "N/A",
    systemClockOffsetMs: 0,
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

  bool get valid => !corrupted && !truncated && !outOfOrder && !duplicateEvents;

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
      List<FindingEntry> findingsList =
          list.map((i) => FindingEntry.fromJson(i)).toList();
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
      changedKeys: json['changed_keys'] != null
          ? List<String>.from(json['changed_keys'])
          : null,
    );
  }

  static const BeforeAfterDiffSnapshot unknown = BeforeAfterDiffSnapshot(
    timestampUtc: "N/A",
    beforeState: {},
    afterState: {},
  );
}
