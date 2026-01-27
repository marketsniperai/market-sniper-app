// import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../domain/universe/core20_universe.dart';

enum UniverseState {
  live,
  stale,
  unavailable,
}

class ExtendedSector {
  final String name;
  final int count;
  final List<String> topSymbols; // Just strings for UI now

  const ExtendedSector(
      {required this.name, required this.count, required this.topSymbols});
}

class ExtendedGovernanceSnapshot {
  final int cooldownSeconds;
  final int dailyCap;
  final int? runsToday;
  final DateTime? nextEligibleUtc;
  final String source; // CANON, ENDPOINT, UNAVAILABLE
  final UniverseState state; // NOMINAL, DEGRADED, UNAVAILABLE

  const ExtendedGovernanceSnapshot({
    required this.cooldownSeconds,
    required this.dailyCap,
    this.runsToday,
    this.nextEligibleUtc,
    required this.source,
    required this.state,
  });

  static const policyOnly = ExtendedGovernanceSnapshot(
    cooldownSeconds: 600, // 10 minutes
    dailyCap: 100,
    runsToday: null,
    nextEligibleUtc: null,
    source: "CANON",
    state: UniverseState.stale, // Degraded because it's policy only
  );
}

class ExtendedUniverseSnapshot {
  final UniverseState state; // UNAVAILABLE, PARTIAL, LIVE
  final int totalCount;
  final List<ExtendedSector> sectors;
  final ExtendedGovernanceSnapshot governance; // New D39.03
  final String? source;

  const ExtendedUniverseSnapshot({
    required this.state,
    required this.totalCount,
    required this.sectors,
    this.governance = ExtendedGovernanceSnapshot.policyOnly,
    this.source,
  });

  static const empty = ExtendedUniverseSnapshot(
    state: UniverseState.unavailable,
    totalCount: 0,
    sectors: [],
    source: "UNAVAILABLE",
  );
}

class OverlayTruthSnapshot {
  final String mode; // LIVE, SIM, PARTIAL, UNKNOWN
  final int ageSeconds;
  final String freshnessState; // OK, STALE
  final String confidence; // HIGH, MEDIUM, LOW, UNKNOWN
  final String source; // ARTIFACT, FALLBACK
  final UniverseState state; // NOMINAL, DEGRADED, UNAVAILABLE

  const OverlayTruthSnapshot({
    required this.mode,
    required this.ageSeconds,
    required this.freshnessState,
    required this.confidence,
    required this.source,
    required this.state,
  });

  static const unavailable = OverlayTruthSnapshot(
    mode: "UNKNOWN",
    ageSeconds: 0,
    freshnessState: "UNKNOWN",
    confidence: "UNKNOWN",
    source: "FALLBACK",
    state: UniverseState.unavailable,
  );

  factory OverlayTruthSnapshot.fromJson(Map<String, dynamic> json) {
    // Expects the 'overlay_truth' subsection of the composer artifact
    return OverlayTruthSnapshot(
      mode: json['mode'] as String? ?? 'UNKNOWN',
      ageSeconds: json['age_seconds'] as int? ?? 0,
      freshnessState: json['ok_state'] as String? ?? 'UNKNOWN',
      confidence: json['confidence'] as String? ?? 'UNKNOWN',
      source: "ARTIFACT",
      state: (json['ok_state'] == 'OK' || json['ok_state'] == 'LIVE')
          ? UniverseState.live
          : ((json['ok_state'] == 'STALE')
              ? UniverseState.stale
              : UniverseState.unavailable),
    );
  }
}

// ...

// ...

class UniverseIntegritySnapshot {
  final String coreStatus; // OK, DEGRADED, UNAVAILABLE
  final String extendedStatus; // OK, DEGRADED, UNAVAILABLE
  final String overlayStatus; // OK, STALE, UNAVAILABLE
  final String governanceStatus; // POLICY_ONLY, TELEMETRY, UNAVAILABLE
  final String consumersStatus; // UNKNOWN, OK, ISSUES, UNAVAILABLE
  final int? freshnessAgeSeconds;
  final String freshnessState; // OK, STALE, UNAVAILABLE
  final String overallState; // NOMINAL, DEGRADED, INCIDENT, UNAVAILABLE
  final String source; // ARTIFACT, POLICY, MIXED

  const UniverseIntegritySnapshot({
    required this.coreStatus,
    required this.extendedStatus,
    required this.overlayStatus,
    required this.governanceStatus,
    required this.consumersStatus,
    required this.freshnessAgeSeconds,
    required this.freshnessState,
    required this.overallState,
    required this.source,
  });

  static const empty = UniverseIntegritySnapshot(
    coreStatus: "UNAVAILABLE",
    extendedStatus: "UNAVAILABLE",
    overlayStatus: "UNAVAILABLE",
    governanceStatus: "UNAVAILABLE",
    consumersStatus: "UNKNOWN",
    freshnessAgeSeconds: null,
    freshnessState: "UNAVAILABLE",
    overallState: "UNAVAILABLE",
    source: "EMPTY",
  );
}

class UniversePropagationAuditSnapshot {
  final String status; // OK, ISSUES, UNAVAILABLE
  final int? consumersTotal;
  final int? consumersOk;
  final int? consumersIssues;
  final List<String> issuesSample;
  final int? ageSeconds;
  final String source;

  const UniversePropagationAuditSnapshot({
    required this.status,
    required this.consumersTotal,
    required this.consumersOk,
    required this.consumersIssues,
    required this.issuesSample,
    required this.ageSeconds,
    required this.source,
  });

  static const unavailable = UniversePropagationAuditSnapshot(
    status: "UNAVAILABLE",
    consumersTotal: null,
    consumersOk: null,
    consumersIssues: null,
    issuesSample: [],
    ageSeconds: null,
    source: "UNAVAILABLE",
  );
}

class ExtendedOverlaySummarySnapshot {
  final List<String> summaryPoints;
  final String source; // ARTIFACT, UNAVAILABLE

  const ExtendedOverlaySummarySnapshot({
    required this.summaryPoints,
    required this.source,
  });

  static const unavailable = ExtendedOverlaySummarySnapshot(
    summaryPoints: [],
    source: "UNAVAILABLE",
  );

  factory ExtendedOverlaySummarySnapshot.fromJson(Map<String, dynamic> json) {
    // Expects the 'overlay_summary' subsection
    return ExtendedOverlaySummarySnapshot(
      summaryPoints: (json['bullets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      source: "ARTIFACT",
    );
  }
}

class SectorSentinelStatusSnapshot {
  final String status; // ACTIVE, STALE, DISABLED, UNAVAILABLE
  final DateTime? asOfUtc;
  final int? ageSeconds;
  final String source; // TAPE, UNAVAILABLE

  const SectorSentinelStatusSnapshot({
    required this.status,
    required this.asOfUtc,
    required this.ageSeconds,
    required this.source,
  });

  static const unavailable = SectorSentinelStatusSnapshot(
    status: "UNAVAILABLE",
    asOfUtc: null,
    ageSeconds: null,
    source: "UNAVAILABLE",
  );
}

class SectorHeatmapSnapshot {
  final Map<String, String>
      sectorStates; // Symbol -> HIGH/NORMAL/LOW/UNAVAILABLE
  final String source; // OVERLAY, EXTENDED, UNAVAILABLE

  const SectorHeatmapSnapshot({
    required this.sectorStates,
    required this.source,
  });

  static const unavailable = SectorHeatmapSnapshot(
    sectorStates: {},
    source: "UNAVAILABLE",
  );
}

class SectorSentinelSectorStatus {
  final String sector;
  final String status; // OK, DEGRADED, UNAVAILABLE, ACTIVE, STALE
  final int? sampleCount;
  final String? pressure; // UP, DOWN, FLAT, MIXED
  final String? dispersion; // HIGH, NORMAL, LOW
  final int? freshnessSeconds;

  const SectorSentinelSectorStatus({
    required this.sector,
    required this.status,
    this.sampleCount,
    this.pressure,
    this.dispersion,
    this.freshnessSeconds,
  });

  factory SectorSentinelSectorStatus.fromJson(Map<String, dynamic> json) {
    return SectorSentinelSectorStatus(
      sector: json['sector_id'] as String? ?? 'UNKNOWN',
      status: json['status'] as String? ?? 'UNKNOWN',
      sampleCount: json['sample_count'] as int?,
      pressure: json['pressure'] as String?,
      dispersion: json['dispersion'] as String?,
      freshnessSeconds: json['freshness_seconds'] as int?,
    );
  }
}

class SectorSentinelSnapshot {
  final String state; // ACTIVE, STALE, DISABLED, UNAVAILABLE
  final DateTime? asOfUtc;
  final int? ageSeconds;
  final DateTime? lastIngestUtc;
  final List<SectorSentinelSectorStatus> sectors; // 11 max

  const SectorSentinelSnapshot({
    required this.state,
    required this.asOfUtc,
    required this.ageSeconds,
    this.lastIngestUtc,
    required this.sectors,
  });

  static const unavailable = SectorSentinelSnapshot(
    state: "UNAVAILABLE",
    asOfUtc: null,
    ageSeconds: null,
    lastIngestUtc: null,
    sectors: [],
  );

  factory SectorSentinelSnapshot.fromJson(Map<String, dynamic> json) {
    return SectorSentinelSnapshot(
      state: json['status'] as String? ?? 'UNAVAILABLE',
      asOfUtc: json['as_of_utc'] != null
          ? DateTime.tryParse(json['as_of_utc'])
          : null,
      ageSeconds: json['age_seconds'] as int?,
      lastIngestUtc: json['last_ingest_utc'] != null
          ? DateTime.tryParse(json['last_ingest_utc'])
          : null,
      sectors: (json['sectors'] as List<dynamic>?)
              ?.map((e) => SectorSentinelSectorStatus.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SentinelHeatCell {
  final String sector;
  final String pressure; // UP, DOWN, MIXED, FLAT, UNAVAILABLE
  final String dispersion; // HIGH, NORMAL, LOW, UNAVAILABLE

  const SentinelHeatCell({
    required this.sector,
    required this.pressure,
    required this.dispersion,
  });

  factory SentinelHeatCell.fromJson(Map<String, dynamic> json) {
    return SentinelHeatCell(
      sector: json['sector_id'] as String? ?? 'UNKNOWN',
      pressure: json['pressure'] as String? ?? 'UNAVAILABLE',
      dispersion: json['dispersion'] as String? ?? 'UNAVAILABLE',
    );
  }
}

class SentinelHeatmapSnapshot {
  final String state; // ACTIVE, STALE, UNAVAILABLE
  final DateTime? asOfUtc;
  final int? ageSeconds;
  final List<SentinelHeatCell> cells; // 11 max

  const SentinelHeatmapSnapshot({
    required this.state,
    required this.asOfUtc,
    required this.ageSeconds,
    required this.cells,
  });

  static const unavailable = SentinelHeatmapSnapshot(
    state: "UNAVAILABLE",
    asOfUtc: null,
    ageSeconds: null,
    cells: [],
  );

  factory SentinelHeatmapSnapshot.fromJson(Map<String, dynamic> json) {
    return SentinelHeatmapSnapshot(
      state: json['status'] as String? ?? 'UNAVAILABLE',
      asOfUtc: json['as_of_utc'] != null
          ? DateTime.tryParse(json['as_of_utc'])
          : null,
      ageSeconds: json['age_seconds'] as int?,
      cells: (json['sectors'] as List<dynamic>?) // Consumes same sectors list
              ?.map((e) => SentinelHeatCell.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class GlobalPulseSynthesisSnapshot {
  final String state; // RISK_ON, RISK_OFF, SHOCK, FRACTURED, UNAVAILABLE
  final DateTime? asOfUtc;
  final int? ageSeconds;
  final List<String> drivers; // Max 3
  final String? confidenceBand; // LOW, MED, HIGH

  const GlobalPulseSynthesisSnapshot({
    required this.state,
    required this.asOfUtc,
    required this.ageSeconds,
    required this.drivers,
    this.confidenceBand,
  });

  static const unavailable = GlobalPulseSynthesisSnapshot(
    state: "UNAVAILABLE",
    asOfUtc: null,
    ageSeconds: null,
    drivers: [],
  );
}

class RealTimeFreshnessSnapshot {
  final int? coreTapeAgeSeconds;
  final int? sentinelAgeSeconds;
  final int? overlayAgeSeconds;
  final int? synthesisAgeSeconds;
  final String overall; // LIVE, STALE, UNAVAILABLE

  const RealTimeFreshnessSnapshot({
    this.coreTapeAgeSeconds,
    this.sentinelAgeSeconds,
    this.overlayAgeSeconds,
    this.synthesisAgeSeconds,
    required this.overall,
  });

  static const unavailable = RealTimeFreshnessSnapshot(
    overall: "UNAVAILABLE",
  );
}

class DisagreementItem {
  final String
      scope; // CORE_vs_PULSE, PULSE_vs_SENTINEL, SENTINEL_vs_OVERLAY, OVERLAY_vs_SYNTHESIS
  final String severity; // LOW, MED, HIGH
  final String message;
  final String? evidence;

  const DisagreementItem({
    required this.scope,
    required this.severity,
    required this.message,
    this.evidence,
  });
}

class DisagreementReportSnapshot {
  final String status; // LIVE, STALE, UNAVAILABLE
  final DateTime? asOfUtc;
  final int? ageSeconds;
  final List<DisagreementItem> disagreements; // Max 6

  const DisagreementReportSnapshot({
    required this.status,
    required this.asOfUtc,
    required this.ageSeconds,
    required this.disagreements,
  });

  static const unavailable = DisagreementReportSnapshot(
    status: "UNAVAILABLE",
    asOfUtc: null,
    ageSeconds: null,
    disagreements: [],
  );
}

class TimelineEntry {
  final String state; // RISK_ON, RISK_OFF, SHOCK, FRACTURED
  final DateTime tsUtc;
  final String? note;

  const TimelineEntry({
    required this.state,
    required this.tsUtc,
    this.note,
  });
}

class GlobalPulseTimelineSnapshot {
  final String status; // LIVE, STALE, UNAVAILABLE
  final DateTime? asOfUtc;
  final int? ageSeconds;
  final List<TimelineEntry> entries; // Max 5

  const GlobalPulseTimelineSnapshot({
    required this.status,
    required this.asOfUtc,
    required this.ageSeconds,
    required this.entries,
  });

  static const unavailable = GlobalPulseTimelineSnapshot(
    status: "UNAVAILABLE",
    asOfUtc: null,
    ageSeconds: null,
    entries: [],
  );
}

class WhatChangedItem {
  final String message;
  final String scope; // PULSE, CORE, SENTINEL, SYSTEM
  final DateTime? timestamp;

  const WhatChangedItem({
    required this.message,
    required this.scope,
    this.timestamp,
  });
}

class WhatChangedSnapshot {
  final String status; // LIVE, UNAVAILABLE
  final List<WhatChangedItem> items; // Max 4

  const WhatChangedSnapshot({
    required this.status,
    required this.items,
  });

  static const unavailable = WhatChangedSnapshot(
    status: "UNAVAILABLE",
    items: [],
  );
}

class CoreUniverseTapeSnapshot {
  final String status; // LIVE, STALE, UNAVAILABLE
  final DateTime? lastUpdateUtc;
  final int? freshnessSeconds;
  final bool sizeGuard; // True if size constraints met (20/21)
  final String source; // TAPE, UNAVAILABLE

  const CoreUniverseTapeSnapshot({
    required this.status,
    required this.lastUpdateUtc,
    required this.freshnessSeconds,
    required this.sizeGuard,
    required this.source,
  });

  static const unavailable = CoreUniverseTapeSnapshot(
    status: "UNAVAILABLE",
    lastUpdateUtc: null,
    freshnessSeconds: null,
    sizeGuard: false,
    source: "UNAVAILABLE",
  );
}

class PulseCoreSnapshot {
  final String state; // RISK_ON, RISK_OFF, SHOCK, UNAVAILABLE
  final DateTime? asOfUtc;
  final int? ageSeconds;
  final double? confidence; // 0.0 - 1.0 (optional)
  final String source; // POLICY, SIM, LIVE, UNAVAILABLE

  const PulseCoreSnapshot({
    required this.state,
    required this.asOfUtc,
    required this.ageSeconds,
    this.confidence,
    required this.source,
  });

  static const unavailable = PulseCoreSnapshot(
    state: "UNAVAILABLE",
    asOfUtc: null,
    ageSeconds: null,
    source: "UNAVAILABLE",
  );
}

class PulseConfidenceSnapshot {
  final String confidenceBand; // LOW, MEDIUM, HIGH, UNAVAILABLE
  final String stabilityBand; // UNSTABLE, TRANSITIONING, STABLE, UNAVAILABLE
  final String volatilityRegime; // LOW, NORMAL, ELEVATED, UNAVAILABLE
  final String source; // POLICY, UNAVAILABLE

  const PulseConfidenceSnapshot({
    required this.confidenceBand,
    required this.stabilityBand,
    required this.volatilityRegime,
    required this.source,
  });

  static const unavailable = PulseConfidenceSnapshot(
    confidenceBand: "UNAVAILABLE",
    stabilityBand: "UNAVAILABLE",
    volatilityRegime: "UNAVAILABLE",
    source: "UNAVAILABLE",
  );
}

class PulseDriftSnapshot {
  final String coreAgreement; // AGREE, DISAGREE, UNKNOWN
  final String sentinelAgreement; // AGREE, DISAGREE, UNKNOWN
  final String overlayAgreement; // AGREE, DISAGREE, UNKNOWN
  final List<String> notes;

  const PulseDriftSnapshot({
    required this.coreAgreement,
    required this.sentinelAgreement,
    required this.overlayAgreement,
    this.notes = const [],
  });

  static const unavailable = PulseDriftSnapshot(
    coreAgreement: "UNKNOWN",
    sentinelAgreement: "UNKNOWN",
    overlayAgreement: "UNKNOWN",
    notes: [],
  );
}

class UniverseDriftSnapshot {
  final String status; // OK, ISSUES, UNAVAILABLE
  final List<String> missingSymbols;
  final List<String> duplicateSymbols;
  final List<String> unknownSymbols;
  final List<String> orphanSymbols;
  final int? ageSeconds;
  final String source; // RUNTIME_PROOF, ARTIFACT, UNAVAILABLE

  const UniverseDriftSnapshot({
    required this.status,
    required this.missingSymbols,
    required this.duplicateSymbols,
    required this.unknownSymbols,
    required this.orphanSymbols,
    required this.ageSeconds,
    required this.source,
  });

  static const unavailable = UniverseDriftSnapshot(
    status: "UNAVAILABLE",
    missingSymbols: [],
    duplicateSymbols: [],
    unknownSymbols: [],
    orphanSymbols: [],
    ageSeconds: null,
    source: "UNAVAILABLE",
  );
}

class AutoRiskActionItem {
  final String actionId;
  final String title;
  final String description;
  final String rationale;
  final String scope; // SYSTEM, UI, DATA
  final String status; // PROPOSED, ACTIVE, SKIPPED
  final int? cooldownSeconds;

  const AutoRiskActionItem({
    required this.actionId,
    required this.title,
    required this.description,
    required this.rationale,
    required this.scope,
    required this.status,
    this.cooldownSeconds,
  });

  factory AutoRiskActionItem.fromJson(Map<String, dynamic> json) {
    return AutoRiskActionItem(
      actionId: json['action_id'] as String? ?? 'UNKNOWN',
      title: json['title'] as String? ?? 'Unknown Action',
      description: json['description'] as String? ?? '',
      rationale: json['rationale'] as String? ?? '',
      scope: json['scope'] as String? ?? 'SYSTEM',
      status: json['status'] as String? ?? 'PROPOSED',
      cooldownSeconds: json['cooldown_seconds'] as int?,
    );
  }
}

class AutoRiskActionSnapshot {
  final String state; // ACTIVE, STALE, UNAVAILABLE
  final DateTime? asOfUtc;
  final int? ageSeconds;
  final List<AutoRiskActionItem> actions; // Max 3

  const AutoRiskActionSnapshot({
    required this.state,
    required this.asOfUtc,
    required this.ageSeconds,
    required this.actions,
  });

  static const unavailable = AutoRiskActionSnapshot(
    state: "UNAVAILABLE",
    asOfUtc: null,
    ageSeconds: null,
    actions: [],
  );

  factory AutoRiskActionSnapshot.fromJson(Map<String, dynamic> json) {
    return AutoRiskActionSnapshot(
      state: json['state'] as String? ?? 'UNAVAILABLE',
      asOfUtc: json['as_of_utc'] != null
          ? DateTime.tryParse(json['as_of_utc'])
          : null,
      ageSeconds: json['age_seconds'] as int?,
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => AutoRiskActionItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class UniverseSnapshot {
  final String source; // REMOTE or LOCAL_CANON_FALLBACK
  final List<SymbolDefinition> coreSymbols;
  final ExtendedUniverseSnapshot extended; // New D39.02
  final OverlayTruthSnapshot overlay; // New D39.04
  final ExtendedOverlaySummarySnapshot summary; // New D39.05
  final SectorSentinelStatusSnapshot sectorSentinel; // New D39.11
  final SectorSentinelSnapshot sectorSentinelRT; // New D40.03
  final SectorHeatmapSnapshot sectorHeatmap; // New D39.10
  final SentinelHeatmapSnapshot sentinelHeatmap; // New D40.11
  final GlobalPulseSynthesisSnapshot synthesis; // New D40.05
  final RealTimeFreshnessSnapshot rtFreshness; // New D40.13
  final DisagreementReportSnapshot disagreementReport; // New D40.06
  final GlobalPulseTimelineSnapshot pulseTimeline; // New D40.12
  final WhatChangedSnapshot whatChanged; // New D40.15
  final AutoRiskActionSnapshot autoRisk; // New D40.08
  final CoreUniverseTapeSnapshot coreTape; // New D40.01
  final PulseCoreSnapshot pulseCore; // New D40.02
  final PulseConfidenceSnapshot pulseConfidence; // New D40.09
  final PulseDriftSnapshot pulseDrift; // New D40.10
  final UniversePropagationAuditSnapshot propagation; // New D39.06
  final UniverseDriftSnapshot drift; // New D39.09
  final UniverseIntegritySnapshot integrity; // New D39.08
  final DateTime? asOfUtc;
  final int? ageSeconds;
  final UniverseState state;

  const UniverseSnapshot({
    required this.source,
    required this.coreSymbols,
    this.extended = ExtendedUniverseSnapshot.empty,
    this.overlay = OverlayTruthSnapshot.unavailable,
    this.summary = ExtendedOverlaySummarySnapshot.unavailable, // Default
    this.sectorSentinel = SectorSentinelStatusSnapshot.unavailable, // Default
    this.sectorSentinelRT = SectorSentinelSnapshot.unavailable, // Default
    this.sectorHeatmap = SectorHeatmapSnapshot.unavailable, // Default
    this.sentinelHeatmap = SentinelHeatmapSnapshot.unavailable, // Default
    this.synthesis = GlobalPulseSynthesisSnapshot.unavailable, // Default
    this.rtFreshness = RealTimeFreshnessSnapshot.unavailable, // Default
    this.disagreementReport = DisagreementReportSnapshot.unavailable, // Default
    this.pulseTimeline = GlobalPulseTimelineSnapshot.unavailable, // Default
    this.whatChanged = WhatChangedSnapshot.unavailable, // Default
    this.autoRisk = AutoRiskActionSnapshot.unavailable, // Default
    this.coreTape = CoreUniverseTapeSnapshot.unavailable, // Default
    this.pulseCore = PulseCoreSnapshot.unavailable, // Default
    this.pulseConfidence = PulseConfidenceSnapshot.unavailable, // Default
    this.pulseDrift = PulseDriftSnapshot.unavailable, // Default
    this.propagation = UniversePropagationAuditSnapshot.unavailable,
    this.drift = UniverseDriftSnapshot.unavailable, // Default
    required this.integrity,
    this.asOfUtc,
    this.ageSeconds,
    required this.state,
  });

  bool get isFallback => source == "LOCAL_CANON_FALLBACK";
}

class OverlayDegradePolicy {
  // Precedence: UNAVAILABLE > STALE > DEGRADED > NOMINAL

  static const int staleThresholdSeconds = 300; // 5 minutes

  static OverlayTruthSnapshot evaluate({
    required String? mode,
    required DateTime? timestamp,
  }) {
    // 1. Missing Data -> UNAVAILABLE
    if (mode == null || timestamp == null) {
      return OverlayTruthSnapshot.unavailable;
    }

    final age = DateTime.now().difference(timestamp).inSeconds;

    // 2. Stale Data -> STALE (Degraded)
    if (age > staleThresholdSeconds) {
      return OverlayTruthSnapshot(
        mode: mode,
        ageSeconds: age,
        freshnessState: "STALE",
        confidence: "LOW",
        source: "FALLBACK",
        state: UniverseState.stale,
      );
    }

    // 3. Partial/Sim Mode -> DEGRADED
    if (mode == "PARTIAL" || mode == "SIM") {
      return OverlayTruthSnapshot(
        mode: mode,
        ageSeconds: age,
        freshnessState: "OK",
        confidence: mode == "SIM" ? "LOW" : "MEDIUM",
        source: "RUNTIME", // Assumed runtime if fresh
        state: UniverseState.stale, // Maps to DEGRADED in Integrity
      );
    }

    // 4. Live + Fresh -> NOMINAL
    return OverlayTruthSnapshot(
      mode: "LIVE",
      ageSeconds: age,
      freshnessState: "OK",
      confidence: "HIGH",
      source: "RUNTIME",
      state: UniverseState.live,
    );
  }
}

class UniverseRepository {
  final ApiClient api;

  UniverseRepository({required this.api});

  Future<UniverseSnapshot> fetchUniverse() async {
    // Component Stubs (In D40 these will come from API)
    const coreState = UniverseState.live;
    const extended = ExtendedUniverseSnapshot.empty;

    // D40.04: Fetch Extended Overlay (Source: Sector Sentinel)
    OverlayTruthSnapshot overlay;
    ExtendedOverlaySummarySnapshot summary;

    try {
      final overlayMap = await api.fetchLiveOverlay();
      // Check for valid data envelope
      if (overlayMap.isNotEmpty && overlayMap['data'] != null) {
        final data = overlayMap['data'];
        final status = data['status'] as String? ?? 'N_A';
        final age = data['age_seconds'] as int? ?? 0;

        // Map Status -> OverlayTruth
        if (status == 'LIVE') {
          overlay = OverlayTruthSnapshot(
              mode: 'LIVE',
              ageSeconds: age,
              freshnessState: 'OK',
              confidence: 'HIGH',
              source: 'SECTOR_SENTINEL',
              state: UniverseState.live);
        } else if (status == 'PARTIAL') {
          overlay = OverlayTruthSnapshot(
              mode: 'PARTIAL',
              ageSeconds: age,
              freshnessState: 'OK',
              confidence: 'MEDIUM',
              source: 'SECTOR_SENTINEL',
              state: UniverseState.live // Functionally live but flagged
              );
        } else if (status == 'STALE') {
          overlay = OverlayTruthSnapshot(
              mode: 'LIVE', // Still live mode, just old
              ageSeconds: age,
              freshnessState: 'STALE',
              confidence: 'LOW',
              source: 'SECTOR_SENTINEL',
              state: UniverseState.stale);
        } else {
          // N_A or ERROR
          overlay = OverlayTruthSnapshot.unavailable;
        }

        // Map Summary
        summary = ExtendedOverlaySummarySnapshot(
            summaryPoints: (data['summary_lines'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            source: (status == 'N_A') ? 'UNAVAILABLE' : 'ARTIFACT');
      } else {
        // API Failed
        overlay = OverlayTruthSnapshot.unavailable;
        summary = ExtendedOverlaySummarySnapshot.unavailable;
      }
    } catch (e) {
      // Fallback
      overlay = OverlayTruthSnapshot.unavailable;
      summary = ExtendedOverlaySummarySnapshot.unavailable;
    }

    // D39.05 Summary is now populated above via D40.04

    // Stub definition for D39.11 - Defaults to UNAVAILABLE
    const sectorSentinel = SectorSentinelStatusSnapshot.unavailable;
    // Stub definition for D40.03 - Defaults to UNAVAILABLE
    const sectorSentinelRT = SectorSentinelSnapshot.unavailable;

    // Stub definition for D39.10 - Defaults to UNAVAILABLE
    const sectorHeatmap = SectorHeatmapSnapshot.unavailable;
    // Stub definition for D40.11 - Defaults to UNAVAILABLE
    const sentinelHeatmap = SentinelHeatmapSnapshot.unavailable;

    // Stub definition for D40.05 - Defaults to UNAVAILABLE
    const synthesis = GlobalPulseSynthesisSnapshot.unavailable;
    // Stub definition for D40.13 - Defaults to UNAVAILABLE
    const rtFreshness = RealTimeFreshnessSnapshot.unavailable;

    // Stub definition for D40.06 - Defaults to UNAVAILABLE
    const disagreementReport = DisagreementReportSnapshot.unavailable;
    // Stub definition for D40.12 - Defaults to UNAVAILABLE
    const pulseTimeline = GlobalPulseTimelineSnapshot.unavailable;
    // Stub definition for D40.15 - Defaults to UNAVAILABLE
    const whatChanged = WhatChangedSnapshot.unavailable;
    // Stub definition for D40.08 - Defaults to UNAVAILABLE
    const autoRisk = AutoRiskActionSnapshot.unavailable;

    // Stub definition for D40.01 - Defaults to UNAVAILABLE
    const coreTape = CoreUniverseTapeSnapshot.unavailable;

    // Stub definitions for D40.02, D40.09, D40.10 - Default to UNAVAILABLE
    const pulseCore = PulseCoreSnapshot.unavailable;
    const pulseConfidence = PulseConfidenceSnapshot.unavailable;
    const pulseDrift = PulseDriftSnapshot.unavailable;

    const propagation = UniversePropagationAuditSnapshot.unavailable;
    const drift = UniverseDriftSnapshot.unavailable;

    // Calculate Integrity
    final integrity =
        _deriveIntegrity(coreState, extended, overlay, propagation, drift);

    return UniverseSnapshot(
      source: "LOCAL_CANON_FALLBACK",
      coreSymbols: CoreUniverse.definitions,
      extended: extended,
      overlay: overlay,
      summary: summary,
      sectorSentinel: sectorSentinel,
      sectorSentinelRT: sectorSentinelRT,
      sectorHeatmap: sectorHeatmap,
      sentinelHeatmap: sentinelHeatmap,
      synthesis: synthesis,
      rtFreshness: rtFreshness,
      disagreementReport: disagreementReport,
      pulseTimeline: pulseTimeline,
      whatChanged: whatChanged,
      autoRisk: autoRisk,
      coreTape: coreTape,
      pulseCore: pulseCore,
      pulseConfidence: pulseConfidence,
      pulseDrift: pulseDrift,
      propagation: propagation,
      drift: drift,
      integrity: integrity,
      state: UniverseState
          .live, // Overall system might still be live even if overlay is unavailable
      asOfUtc: null,
      ageSeconds: 0,
    );
  }

  UniverseIntegritySnapshot _deriveIntegrity(
    UniverseState coreState,
    ExtendedUniverseSnapshot extended,
    OverlayTruthSnapshot overlay,
    UniversePropagationAuditSnapshot propagation,
    UniverseDriftSnapshot drift,
  ) {
    // 1. Component Statuses
    final coreStatus = coreState == UniverseState.live ? "OK" : "UNAVAILABLE";

    final extendedStatus =
        extended.state == UniverseState.unavailable ? "UNAVAILABLE" : "OK";

    final overlayStatus = overlay.state == UniverseState.unavailable
        ? "UNAVAILABLE"
        : (overlay.freshnessState == "STALE" ? "STALE" : "OK");

    final governanceStatus = extended.governance.source == "CANON"
        ? "POLICY_ONLY"
        : (extended.governance.source == "ENDPOINT"
            ? "TELEMETRY"
            : "UNAVAILABLE");

    final consumersStatus =
        propagation.status == "UNAVAILABLE" ? "UNKNOWN" : propagation.status;

    // 2. Freshness from Overlay
    final freshnessAge = overlay.ageSeconds;
    final freshnessState = overlay.state == UniverseState.unavailable
        ? "UNAVAILABLE"
        : overlay.freshnessState;

    // 3. Overall State derivation (Precedence: UNAVAILABLE > INCIDENT > DEGRADED > NOMINAL)
    String overall = "NOMINAL";

    // Level 4: UNAVAILABLE (Critical Truth Missing)
    if (overlay.state == UniverseState.unavailable) {
      overall = "UNAVAILABLE";
    }

    // Level 3: INCIDENT (Live but Stale is dangerous)
    if (overlay.mode == "LIVE" && overlay.freshnessState == "STALE") {
      overall = "INCIDENT";
    }

    // Level 2: DEGRADED (Partial, Sim, or component issues)
    if (overall != "UNAVAILABLE" && overall != "INCIDENT") {
      if (overlay.mode == "SIM" ||
          overlay.mode == "PARTIAL" ||
          governanceStatus == "POLICY_ONLY" ||
          extendedStatus == "UNAVAILABLE" ||
          consumersStatus == "ISSUES" ||
          drift.status == "ISSUES") {
        overall = "DEGRADED";
      }
    }

    // Level 1: NOMINAL (Only if everything matches)

    return UniverseIntegritySnapshot(
      coreStatus: coreStatus,
      extendedStatus: extendedStatus,
      overlayStatus: overlayStatus,
      governanceStatus: governanceStatus,
      consumersStatus: consumersStatus,
      freshnessAgeSeconds: freshnessAge,
      freshnessState: freshnessState,
      overallState: overall,
      source: "MIXED",
    );
  }
}
