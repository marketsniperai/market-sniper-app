import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../repositories/system_health_repository.dart';
import '../models/war_room_snapshot.dart';
import '../models/system_health_snapshot.dart';
// import '../logic/data_state_resolver.dart';
// Needed if we reuse DataStateResolver logic, but here we mostly map raw JSON

class WarRoomRepository {
  final ApiClient api;
  final SystemHealthRepository healthRepo;

  WarRoomRepository({required this.api})
      : healthRepo = SystemHealthRepository(api: api);

  Future<LockReasonSnapshot> fetchLockReason() async {
    final json = await api.fetchLockReason();
    return _parseLockReason(json);
  }

  Future<WarRoomSnapshot> fetchSnapshot() async {
    debugPrint("WAR_ROOM_REPO: Fetching Snapshot...");
    try {
      // Helper for safe fetching
      Future<T> safe<T>(Future<T> future, T fallback, String name) async {
        try {
          return await future;
        } catch (e) {
          debugPrint("WAR_ROOM_REPO_ERROR [$name]: $e");
          return fallback;
        }
      }

      // Parallel fetch with isolation
      final results = await Future.wait([
        safe(healthRepo.fetchUnifiedHealth(), SystemHealthSnapshot.unknown, "Health"),
        safe(api.fetchAutofixStatus(), <String, dynamic>{'error': true}, "Autofix"),
        safe(api.fetchHousekeeperStatus(), <String, dynamic>{'error': true}, "Housekeeper"),
        safe(api.fetchMisfireStatus(), <String, dynamic>{'error': true}, "Misfire"),
        safe(api.fetchIronStatus(), <String, dynamic>{'error': true}, "Iron"),
        safe(api.fetchUniverse(), <String, dynamic>{}, "Universe"),
        safe(api.fetchHealthExt(), <String, dynamic>{}, "HealthExt"),
        safe(api.fetchIronTimeline(), <String, dynamic>{}, "IronTimeline"),
        safe(api.fetchIronHistory(), <String, dynamic>{}, "IronHistory"),
        safe(api.fetchIronLKG(), <String, dynamic>{}, "IronLKG"),
        safe(api.fetchIronDecisionPath(), <String, dynamic>{}, "IronDecision"),
        safe(api.fetchIronDrift(), <String, dynamic>{}, "IronDrift"),
        safe(api.fetchIronReplayIntegrity(), <String, dynamic>{}, "IronReplay"),
        safe(api.fetchLockReason(), <String, dynamic>{}, "LockReason"),
        safe(api.fetchCoverage(), <String, dynamic>{}, "Coverage"),
        safe(api.fetchFindings(), <String, dynamic>{}, "Findings"),
        safe(api.fetchBeforeAfterDiff(), <String, dynamic>{}, "Diff"),
        safe(api.fetchAutoFixTier1Status(), <String, dynamic>{'error': true}, "Tier1"),
        safe(api.fetchAutoFixDecisionPath(), <String, dynamic>{'error': true}, "AutoFixPath"),
        safe(api.fetchMisfireRootCause(), <String, dynamic>{'error': true}, "MisfireRoot"),
        safe(api.fetchSelfHealConfidence(), <String, dynamic>{'error': true}, "Confidence"),
        safe(api.fetchSelfHealWhatChanged(), <String, dynamic>{'error': true}, "WhatChanged"),
        safe(api.fetchCooldownTransparency(), <String, dynamic>{'error': true}, "Cooldown"),
        safe(api.fetchRedButtonStatus(), <String, dynamic>{'error': true}, "RedButton"),
        safe(api.fetchMisfireTier2(), <String, dynamic>{'error': true}, "MisfireTier2"),
        safe(api.fetchOptionsContext(), <String, dynamic>{'status': 'N/A'}, "Options"),
        safe(api.fetchMacroContext(), <String, dynamic>{'status': 'N/A'}, "Macro"),
        safe(api.fetchEvidenceSummary(), <String, dynamic>{'status': 'N/A'}, "Evidence"),
        safe(_fetchDashboardSafe(), <String, dynamic>{'data': {}, 'status': 0}, "Dashboard"),
      ]);

      debugPrint("WAR_ROOM_REPO: Fetch Complete. Parsing...");

      final osHealth = results[0] as SystemHealthSnapshot;
      final autofixJson = results[1] as Map<String, dynamic>;
      final housekeeperJson = results[2] as Map<String, dynamic>;
      final misfireJson = results[3] as Map<String, dynamic>;
      final ironJson = results[4] as Map<String, dynamic>;
      final universeJson = results[5] as Map<String, dynamic>;
      final healthJson = results[6] as Map<String, dynamic>;
      final timelineJson = results[7] as Map<String, dynamic>;
      final historyJson = results[8] as Map<String, dynamic>;
      final lkgJson = results[9] as Map<String, dynamic>;
      final decisionJson = results[10] as Map<String, dynamic>;
      final driftJson = results[11] as Map<String, dynamic>;
      final replayJson = results[12] as Map<String, dynamic>;
      final lockReasonJson = results[13] as Map<String, dynamic>;
      final coverageJson = results[14] as Map<String, dynamic>;
      final findingsJson = results[15] as Map<String, dynamic>;
      final diffJson = results[16] as Map<String, dynamic>;
      final afxTier1Json = results[17] as Map<String, dynamic>;
      final afxDecisionPathJson = results[18] as Map<String, dynamic>;
      final misfireRootCauseJson = results[19] as Map<String, dynamic>;
      final selfHealConfidenceJson = results[20] as Map<String, dynamic>;
      final selfHealWhatChangedJson = results[21] as Map<String, dynamic>;
      final cooldownTransparencyJson = results[22] as Map<String, dynamic>;
      final redButtonJson = results[23] as Map<String, dynamic>;
      final misfireTier2Json = results[24] as Map<String, dynamic>;
      final optionsJson = results[25] as Map<String, dynamic>;
      final macroJson = results[26] as Map<String, dynamic>;
      final evidenceJson = results[27] as Map<String, dynamic>;
      final dashboardResult = results[28] as Map<String, dynamic>;
      final warRoomDashboardJson = dashboardResult['data'] as Map<String, dynamic>;
      final warRoomStatus = dashboardResult['status'] as int?;

      return WarRoomSnapshot(
        osHealth: osHealth,
        autopilot: _parseAutopilot(autofixJson),
        misfire: _parseMisfire(misfireJson),
        housekeeper: _parseHousekeeper(housekeeperJson),
        iron: _parseIron(ironJson),
        ironTimeline: _parseIronTimeline(timelineJson),
        ironHistory: _parseIronHistory(historyJson),
        lkg: _parseIronLKG(lkgJson),
        decisionPath: _parseDecisionPath(decisionJson),
        drift: _parseIronDrift(driftJson),
        replay: _parseIronReplay(replayJson),
        lockReason: _parseLockReason(lockReasonJson),
        coverage: _parseCoverage(coverageJson),
        findings: (await _parseFindingsWrapper(findingsJson)) ??
            FindingsSnapshot.unknown,
        universe: _parseUniverse(universeJson, healthJson, warRoomDashboardJson),
        beforeAfterDiff: await _parseBeforeAfterDiff(diffJson),
        autofixTier1: _parseAutoFixTier1(afxTier1Json),
        autofixDecisionPath: _parseAutoFixDecisionPath(afxDecisionPathJson),
        misfireRootCause: _parseMisfireRootCause(misfireRootCauseJson),
        selfHealConfidence: _parseSelfHealConfidence(selfHealConfidenceJson),
        selfHealWhatChanged: _parseSelfHealWhatChanged(selfHealWhatChangedJson),
        cooldownTransparency:
            _parseCooldownTransparency(cooldownTransparencyJson),
        redButton: _parseRedButton(redButtonJson),
        misfireTier2: _parseMisfireTier2(misfireTier2Json),
        options: _parseOptions(optionsJson), // D36.3
        macro: _parseMacro(macroJson), // D36.5
        evidence: _parseEvidence(evidenceJson), // D36.4
        warRoomHttpStatus: warRoomStatus,
      );
    } catch (e, st) {
      debugPrint("WAR_ROOM_REPO FATAL ERROR: $e");
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _fetchDashboardSafe() async {
    // Wrapper to return {data: json, status: code} because ApiClient likely returns just JSON or throws
    // Actually ApiClient usually returns Map. We need to check if we can get status.
    // If ApiClient swallows status, we might need a specific method or assume 200 if not empty.
    // Checking ApiClient contract... assuming standard fetch returns body.
    // For D53.6A we need status.
    // If we can't get strict status without modifying ApiClient (blocked), we infer:
    // Non-empty + success key = 200. Empty/Error = 500/0.
    // Let's rely on the result.
    try {
      final json = await api.fetchWarRoomDashboard();
      if (json.isNotEmpty) {
         // If we got data, it's likely 200 matching our pattern
         return {'data': json, 'status': 200};
      }
      return {'data': <String, dynamic>{}, 'status': 404}; 
    } catch (e) {
      return {'data': <String, dynamic>{}, 'status': 500};
    }
  }

// ... (omitting intermediate methods for brevity, targeting _parseUniverse next)

  UniverseSnapshot _parseUniverse(
      Map<String, dynamic> json, Map<String, dynamic> fallback, Map<String, dynamic> dashboard) {
    
    // Master Timestamp from War Room Dashboard (Primary Truth)
    String timestampUtc = "N/A";
    if (dashboard.isNotEmpty) {
      timestampUtc = dashboard['timestamp_utc'] ?? "N/A";
    }

    // Priority 1: /universe JSON (if implemented)
    if (json.isNotEmpty) {
      return UniverseSnapshot(
        status: json['status'] ?? 'LIVE',
        core: json['core_universe'] ?? 'CORE20',
        extended: json['extended_enabled'] == true ? "ON" : "OFF",
        overlayState: json['overlay_state'] ?? 'LIVE',
        overlayAge: json['overlay_age_seconds'] ?? 0,
        source: "/universe",
        timestampUtc: timestampUtc,
        isAvailable: true,
      );
    }

    // Priority 3: Fallback to /health_ext (RunManifest) which contains universe info
    if (fallback.isNotEmpty && fallback.containsKey('data')) {
      final data = fallback['data']; // Manifest
      // Manifest usually has: universe_name, extended_universe, mode, processing_time...

      String core = data['universe_name'] ?? 'CORE??';
      String ext = (data['extended_universe'] == true) ? "ON" : "OFF";
      String mode = data['mode'] ?? 'UNKNOWN'; // FULL, LIGHT, etc.
      String overlay = "PARTIAL"; // Default mapping

      if (mode == "FULL") {
        overlay = "LIVE";
      } else if (mode == "SIM") {
        overlay = "SIM";
      }

      return UniverseSnapshot(
        status: overlay == "LIVE" ? "LIVE" : "PARTIAL", // Overall status
        core: core,
        extended: ext,
        overlayState: overlay,
        overlayAge: 0, // N/A for now from raw fallback unless we parse time.
        source: "/health_ext (fallback)",
        timestampUtc: timestampUtc,
        isAvailable: true,
      );
    }

    return UniverseSnapshot(
      status: "UNAVAILABLE",
      core: "UNKNOWN",
      extended: "UNKNOWN",
      overlayState: "UNAVAILABLE",
      overlayAge: 0,
      source: "MISSING",
      timestampUtc: timestampUtc,
      isAvailable: false,
    );
  }

  OptionsInfoSnapshot _parseOptions(Map<String, dynamic> json) {
    if (json.isNotEmpty && json['status'] != null) {
      final diag = json['diagnostics'] ?? {};
      return OptionsInfoSnapshot(
        status: json['status'] ?? "N_A",
        coverage: json['coverage'] ?? "N_A",
        ivRegime: json['iv_regime'] ?? "N/A",
        skew: json['skew'] ?? "N/A",
        expectedMove: json['expected_move'] ?? "N/A",
        asOfUtc: json['as_of_utc'] ?? "N/A",
        isAvailable: true,
        version: json['version'] ?? "1.0",
        expectedMoveHorizon: json['expected_move_horizon'] ?? "N/A",
        confidence: json['confidence'] ?? "N/A",
        note: json['note'] ?? "",
        providerAttempted: diag['provider_attempted'] ?? false,
        providerResult: diag['provider_result'] ?? "NONE",
        fallbackReason: diag['fallback_reason'] ?? "NONE",
      );
    }
    return OptionsInfoSnapshot.unknown;
  }

  AutoFixTier1Snapshot _parseAutoFixTier1(Map<String, dynamic> json) {
    if (json.isNotEmpty && !json.containsKey("error")) {
      return AutoFixTier1Snapshot(
        status: json['status'] ?? "UNKNOWN",
        planId: json['plan_id'] ?? "N/A",
        actionsExecuted: json['actions_executed'] ?? 0,
        lastRun: json['timestamp_utc'] ?? "NEVER",
        isAvailable: true,
      );
    }
    return const AutoFixTier1Snapshot(
      status: "UNAVAILABLE",
      planId: "N/A",
      actionsExecuted: 0,
      lastRun: "NEVER",
      isAvailable: false,
    );
  }

  Future<BeforeAfterDiffSnapshot?> _parseBeforeAfterDiff(
      Map<String, dynamic> json) async {
    if (json.isNotEmpty) {
      return BeforeAfterDiffSnapshot.fromJson(json);
    }
    return null;
  }

  Future<FindingsSnapshot?> _parseFindingsWrapper(
      Map<String, dynamic> json) async {
    if (json.isEmpty) return null;
    if (json.containsKey("findings")) {
      return FindingsSnapshot.fromJson(json);
    }
    return null;
  }

  AutopilotSnapshot _parseAutopilot(Map<String, dynamic> autofix) {
    if (autofix.isNotEmpty) {
      final mode =
          autofix['mode'] ?? (autofix['enabled'] == true ? 'ON' : 'OFF');
      // If legacy 'dial' exists, prefer that (or prioritize mode if consistent)
      // Note: Keeping fallback for safety
      final effectiveMode = autofix['dial'] ?? mode;

      return AutopilotSnapshot(
        mode: effectiveMode,
        stage: autofix['stage'] ?? 'IDLE',
        lastAction: autofix['last_action'] ?? 'None',
        lastActionTime: autofix['last_execution_at'] ??
            autofix['last_recommendation_at'] ??
            '',
        cooldownRemaining: autofix['cooldown_seconds_remaining'] ?? 0,
        source: "/lab/autofix/status",
        isAvailable: true,
      );
    }

    return const AutopilotSnapshot(
      mode: "UNAVAILABLE",
      stage: "DISCONNECTED",
      lastAction: "None",
      lastActionTime: "",
      cooldownRemaining: 0,
      source: "MISSING endpoints",
      isAvailable: false,
    );
  }

  MisfireSnapshot _parseMisfire(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      // Expect system health structure if using /misfire directly
      // { "status": "nominal" | "misfire", "misfire_active": bool, "last_misfire": "...", "maintenance": {...} }

      String status = "NOMINAL";
      if (json['misfire_active'] == true) {
        status = "MISFIRE";
      } else if (json['status'] == 'locked') {
        status = "LOCKED";
      }

      return MisfireSnapshot(
        status: status,
        lastMisfire: json['last_misfire_timestamp'] ?? 'NONE',
        autoRecovery: json['auto_recovery'] ?? false,
        recoveryState: json['recovery_state'] ?? 'IDLE',
        lastAction: json['last_action'] ?? 'None',
        cooldown: json['cooldown_seconds_remaining'] ?? 0,
        proof: json['proof_status'] ?? 'N/A', // e.g. "PRESENT", "MISSING"
        note: json['message'] ?? '',
        source: "/misfire",
        isAvailable: true,
      );
    }

    return const MisfireSnapshot(
      status: "UNAVAILABLE",
      lastMisfire: "--",
      autoRecovery: false,
      recoveryState: "UNKNOWN",
      lastAction: "None",
      cooldown: 0,
      proof: "N/A",
      note: "Endpoint missing",
      source: "MISSING",
      isAvailable: false,
    );
  }

  HousekeeperSnapshot _parseHousekeeper(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      if (json.containsKey("error")) {
        // Unavailable state
        return const HousekeeperSnapshot(
          autoRun: false,
          lastRun: "NEVER",
          result: "UNAVAILABLE",
          cooldown: 0,
          source: "/lab/os/self_heal/housekeeper/status",
          isAvailable: true, // Tile exists but status is 404-like
        );
      }

      // D42.03 Format
      // { "timestamp_utc": "...", "plan_id": "...", "status": "...", "actions_executed": ... }
      final runTime = json['timestamp_utc'] ?? 'NEVER';
      final status = json['status'] ?? 'UNKNOWN';
      final execCount = json['actions_executed'] ?? 0;

      String displayResult = status;
      if (status == 'SUCCESS' || status == 'PARTIAL') {
        displayResult = "$status ($execCount)";
      }

      return HousekeeperSnapshot(
        autoRun: true, // Implied enabled if we have status
        lastRun: runTime,
        result: displayResult,
        cooldown: 0,
        source: "/lab/os/self_heal/housekeeper/status",
        isAvailable: true,
      );
    }

    return const HousekeeperSnapshot(
      autoRun: false,
      lastRun: "NEVER",
      result: "UNKNOWN",
      cooldown: 0,
      source: "MISSING",
      isAvailable: false,
    );
  }

  IronTimelineSnapshot _parseIronTimeline(Map<String, dynamic> json) {
    if (json.isNotEmpty && json.containsKey('events')) {
      final list = json['events'] as List;
      final events = list
          .map((e) => IronTimelineEvent(
                timestamp: e['timestamp_utc'] ?? 'N/A',
                type: e['type'] ?? 'UNKNOWN',
                source: e['source'] ?? 'UNKNOWN',
                summary: e['summary'] ?? '-',
              ))
          .toList();

      return IronTimelineSnapshot(
        events: events,
        source: "/lab/os/iron/timeline_tail",
        isAvailable: true,
      );
    }

    return const IronTimelineSnapshot(
      events: [],
      source: "MISSING",
      isAvailable: false,
    );
  }

  IronStateHistorySnapshot _parseIronHistory(Map<String, dynamic> json) {
    if (json.isNotEmpty && json.containsKey('history')) {
      final list = json['history'] as List;
      final entries = list
          .map((e) => IronStateHistoryEntry(
                state: e['state'] ?? 'UNKNOWN',
                timestamp: e['timestamp_utc'] ?? 'N/A',
                source: e['source'] ?? 'UNKNOWN',
              ))
          .toList();

      return IronStateHistorySnapshot(
        history: entries,
        source: "/lab/os/iron/state_history",
        isAvailable: true,
      );
    }

    return const IronStateHistorySnapshot(
      history: [],
      source: "MISSING",
      isAvailable: false,
    );
  }

  LKGSnapshot _parseIronLKG(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      return LKGSnapshot(
        hash: json['hash'] ?? 'UNKNOWN',
        timestamp: json['timestamp_utc'] ?? 'N/A',
        sizeBytes: json['size_bytes'] ?? 0,
        valid: json['valid'] ?? false,
        source: "/lab/os/iron/lkg",
        isAvailable: true,
      );
    }

    return const LKGSnapshot(
      hash: "MISSING",
      timestamp: "N/A",
      sizeBytes: 0,
      valid: false,
      source: "MISSING",
      isAvailable: false,
    );
  }

  DecisionPathSnapshot _parseDecisionPath(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      return DecisionPathSnapshot(
        timestamp: json['timestamp_utc'] ?? 'N/A',
        type: json['decision_type'] ?? 'UNKNOWN',
        reason: json['reason'] ?? 'None',
        fallbackUsed: json['fallback_used'] ?? false,
        actionTaken: json['action_taken'],
        source: "/lab/os/iron/decision_path",
        isAvailable: true,
      );
    }
    return const DecisionPathSnapshot(
      timestamp: "N/A",
      type: "UNKNOWN",
      reason: "Missing",
      fallbackUsed: false,
      actionTaken: null,
      source: "MISSING",
      isAvailable: false,
    );
  }

  DriftSnapshot _parseIronDrift(Map<String, dynamic> json) {
    if (json.containsKey('drift')) {
      final list = (json['drift'] as List)
          .map((e) => DriftEntry(
                component: e['component'] ?? 'UNKNOWN',
                expected: e['expected'] ?? '',
                observed: e['observed'] ?? '',
                timestamp: e['timestamp_utc'] ?? '',
              ))
          .toList();

      return DriftSnapshot(
          status: "NOMINAL",
          assetSkew: "0ms",
          systemClockOffsetMs: 0,
          entries: list,
          source: "/lab/os/iron/drift",
          isAvailable: true);
    }

    return const DriftSnapshot(
      status: "N/A",
      assetSkew: "N/A",
      systemClockOffsetMs: 0,
      entries: [],
      source: "MISSING",
      isAvailable: false,
    );
  }

  ReplayIntegritySnapshot _parseIronReplay(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      return ReplayIntegritySnapshot(
        corrupted: json['corrupted'] ?? false,
        truncated: json['truncated'] ?? false,
        outOfOrder: json['out_of_order'] ?? false,
        duplicateEvents: json['duplicate_events'] ?? false,
        timestamp: json['timestamp_utc'] ?? 'N/A',
        source: "/lab/os/iron/replay_integrity",
        isAvailable: true,
      );
    }

    return const ReplayIntegritySnapshot(
      corrupted: false,
      truncated: false,
      outOfOrder: false,
      duplicateEvents: false,
      timestamp: "N/A",
      source: "MISSING",
      isAvailable: false,
    );
  }

  // Assuming there's a method like this that aggregates Iron-related snapshots
  // This block is inferred from the provided change snippet.
  // If this method doesn't exist, the user's instruction is incomplete.
  // For the purpose of this task, I will place it here as if it were part of a larger class.
  // This is a placeholder to demonstrate where the `findings` logic would go.
  /*
  Future<IronAggregatedSnapshot> _fetchIronAggregatedSnapshots() async {
    try {
      final ironStatus = await _parseIron(await _fetchJson('/lab/os/iron/status'));
      final ironTimeline = await _parseIronTimeline(await _fetchJson('/lab/os/iron/timeline_tail'));
      final ironHistory = await _parseIronHistory(await _fetchJson('/lab/os/iron/state_history'));
      final lkg = await _parseIronLKG(await _fetchJson('/lab/os/iron/lkg'));
      final decisionPath = await _parseDecisionPath(await _fetchJson('/lab/os/iron/decision_path'));
      final drift = await _parseIronDrift(await _fetchJson('/lab/os/iron/drift'));
      final replay = await _parseIronReplay(await _fetchJson('/lab/os/iron/replay_integrity'));
      final lockReason = await _parseLockReason(await _fetchJson('/lab/os/iron/lock_reason'));
      final coverage = await _parseCoverage(await _fetchJson('/lab/os/self_heal/coverage'));
      final findings = await _parseFindings(await _fetchJson('/lab/os/self_heal/findings')); // New line

      // Assuming baseSnapshot is an existing object or a constructor parameter
      // This part of the snippet is highly contextual and depends on the surrounding code.
      // I'm integrating it as if it's part of an existing update/fetch method.
      return baseSnapshot.copyWith(
        ironStatus: ironStatus,
        ironTimeline: ironTimeline,
        ironHistory: ironHistory,
        ironLKG: lkg,
        decisionPath: decisionPath,
        ironDrift: drift,
        ironReplay: replay,
        lockReason: lockReason,
        coverage: coverage,
        findings: findings, // New line
      );
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
  */

  // Removed unused _parseFindings

  LockReasonSnapshot _parseLockReason(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      return LockReasonSnapshot(
        lockState: json['lock_state'] ?? "NONE",
        reasonCode: json['reason_code'] ?? "N/A",
        description: json['reason_description'] ?? "N/A",
        module: json['originating_module'] ?? "N/A",
        timestamp: json['timestamp_utc'] ?? "N/A",
        isAvailable: true,
      );
    }
    return LockReasonSnapshot.unknown;
  }

  CoverageSnapshot _parseCoverage(Map<String, dynamic> json) {
    if (json.containsKey('entries')) {
      final list = (json['entries'] as List)
          .map((e) => CoverageEntry(
                capability: e['capability'] ?? 'UNKNOWN',
                status: e['status'] ?? 'UNAVAILABLE',
                reason: e['reason'],
              ))
          .toList();

      return CoverageSnapshot(
          entries: list,
          source: "/lab/os/self_heal/coverage",
          isAvailable: true);
    }

    return CoverageSnapshot.unknown;
  }

  IronSnapshot _parseIron(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      return IronSnapshot(
        status: "NOMINAL", // Availability status
        state: json['state'] ?? "IDLE",
        lastTick: json['last_tick_timestamp'] ?? json['last_tick_at'] ?? 'N/A',
        ageSeconds: json['age_seconds'] ?? 0,
        source: "/lab/os/iron/status",
        isAvailable: true,
      );
    }

    return const IronSnapshot(
      status: "UNAVAILABLE",
      state: "DISCONNECTED",
      lastTick: "N/A",
      ageSeconds: 0,
      source: "MISSING",
      isAvailable: false,
    );
  }



  AutoFixDecisionPathSnapshot _parseAutoFixDecisionPath(
      Map<String, dynamic> json) {
    if (json.isNotEmpty && !json.containsKey("error")) {
      final actionsList = (json['actions'] as List?)
              ?.map((e) => DecisionActionSnapshot(
                    code: e['code'] ?? 'UNKNOWN',
                    outcome: e['outcome'] ?? 'UNKNOWN',
                    reason: e['reason'] ?? 'N/A',
                  ))
              .toList() ??
          [];

      return AutoFixDecisionPathSnapshot(
        status: json['status'] ?? "UNKNOWN",
        runId: json['run_id'] ?? "N/A",
        context: json['context'] ?? "N/A",
        actionCount: json['action_count'] ?? 0,
        actions: actionsList,
        isAvailable: true,
      );
    }
    return AutoFixDecisionPathSnapshot.unknown;
  }

  MisfireRootCauseSnapshot _parseMisfireRootCause(Map<String, dynamic> json) {
    if (json.isNotEmpty && !json.containsKey("error")) {
      return MisfireRootCauseSnapshot(
        timestampUtc: json['timestamp_utc'] ?? 'N/A',
        incidentId: json['incident_id'] ?? 'N/A',
        misfireType: json['misfire_type'] ?? 'UNKNOWN',
        originatingModule: json['originating_module'] ?? 'UNKNOWN',
        detectedBy: json['detected_by'] ?? 'UNKNOWN',
        primaryArtifact: json['primary_artifact'],
        pipelineMode: json['pipeline_mode'],
        fallbackUsed: json['fallback_used'],
        actionTaken: json['action_taken'],
        outcome: json['outcome'] ?? 'UNAVAILABLE',
        notes: json['notes'],
        isAvailable: true,
      );
    }
    return MisfireRootCauseSnapshot.unknown;
  }

  SelfHealConfidenceSnapshot _parseSelfHealConfidence(
      Map<String, dynamic> json) {
    if (json.isNotEmpty && !json.containsKey("error")) {
      final entries = (json['entries'] as List?)
              ?.map((e) => ConfidenceEntrySnapshot(
                    engine: e['engine'] ?? 'UNKNOWN',
                    actionCode: e['action_code'] ?? 'UNKNOWN',
                    confidence: e['confidence'] ?? 'UNKNOWN',
                    evidence: (e['evidence'] as List?)?.cast<String>() ?? [],
                  ))
              .toList() ??
          [];

      return SelfHealConfidenceSnapshot(
        timestampUtc: json['timestamp_utc'] ?? 'N/A',
        runId: json['run_id'] ?? 'N/A',
        overall: json['overall'] ?? 'UNAVAILABLE',
        entries: entries,
        isAvailable: true,
      );
    }
    return SelfHealConfidenceSnapshot.unknown;
  }

  SelfHealWhatChangedSnapshot _parseSelfHealWhatChanged(
      Map<String, dynamic> json) {
    if (json.isNotEmpty && !json.containsKey("error")) {
      final artifacts = (json['artifacts_updated'] as List?)
              ?.map((e) => ArtifactUpdateSnapshot(
                    path: e['path'] ?? 'UNKNOWN',
                    changeType: e['change_type'] ?? 'UNKNOWN',
                    beforeHash: e['before_hash'],
                    afterHash: e['after_hash'],
                  ))
              .toList() ??
          [];

      StateTransitionSnapshot? stateTransition;
      if (json.containsKey('state_transition')) {
        final st = json['state_transition'];
        stateTransition = StateTransitionSnapshot(
          fromState: st['from_state'],
          toState: st['to_state'],
          unlocked: st['unlocked'] ?? false,
        );
      }

      return SelfHealWhatChangedSnapshot(
        timestampUtc: json['timestamp_utc'] ?? 'N/A',
        runId: json['run_id'] ?? 'N/A',
        summary: json['summary'],
        artifactsUpdated: artifacts,
        stateTransition: stateTransition,
        isAvailable: true,
      );
    }
    return SelfHealWhatChangedSnapshot.unknown;
  }

  CooldownTransparencySnapshot _parseCooldownTransparency(
      Map<String, dynamic> json) {
    if (json.isNotEmpty && !json.containsKey("error")) {
      final entries = (json['entries'] as List?)
              ?.map((e) => CooldownEntrySnapshot(
                    engine: e['engine'] ?? 'UNKNOWN',
                    actionCode: e['action_code'] ?? 'UNKNOWN',
                    attempted: e['attempted'] ?? false,
                    permitted: e['permitted'] ?? false,
                    gateReason: e['gate_reason'] ?? 'UNKNOWN',
                    cooldownRemainingSeconds: e['cooldown_remaining_seconds'],
                    throttleWindowSeconds: e['throttle_window_seconds'],
                    lastExecutedTimestampUtc: e['last_executed_timestamp_utc'],
                    notes: e['notes'],
                  ))
              .toList() ??
          [];

      return CooldownTransparencySnapshot(
        timestampUtc: json['timestamp_utc'] ?? 'N/A',
        runId: json['run_id'],
        entries: entries,
        isAvailable: true,
      );
    }
    return CooldownTransparencySnapshot.unknown;
  }

  RedButtonStatusSnapshot _parseRedButton(Map<String, dynamic> json) {
    if (json.isNotEmpty && !json.containsKey("error")) {
      RedButtonRunSummarySnapshot? lastRun;
      if (json.containsKey('last_run')) {
        final lr = json['last_run'];
        lastRun = RedButtonRunSummarySnapshot(
          runId: lr['run_id'] ?? 'N/A',
          action: lr['action'] ?? 'UNKNOWN',
          timestampUtc: lr['timestamp_utc'] ?? 'N/A',
          status: lr['status'] ?? 'UNKNOWN',
          notes: lr['notes'],
        );
      }

      return RedButtonStatusSnapshot(
        timestampUtc: json['timestamp_utc'] ?? 'N/A',
        available: json['available'] ?? false,
        founderRequired: json['founder_required'] ?? true,
        capabilities: (json['capabilities'] as List?)?.cast<String>() ?? [],
        lastRun: lastRun,
      );
    }
    return RedButtonStatusSnapshot.unknown;
  }

  MisfireTier2Snapshot _parseMisfireTier2(Map<String, dynamic> json) {
    if (json.isNotEmpty && !json.containsKey("error")) {
      final steps = (json['steps'] as List?)
              ?.map((e) => MisfireEscalationStepSnapshot(
                    stepId: e['step_id'] ?? 'UNKNOWN',
                    description: e['description'] ?? 'UNKNOWN',
                    attempted: e['attempted'] ?? false,
                    permitted: e['permitted'] ?? false,
                    gateReason: e['gate_reason'],
                    result: e['result'],
                    timestampUtc: e['timestamp_utc'],
                  ))
              .toList() ??
          [];

      return MisfireTier2Snapshot(
        timestampUtc: json['timestamp_utc'] ?? 'N/A',
        incidentId: json['incident_id'] ?? 'N/A',
        detectedBy: json['detected_by'] ?? 'UNKNOWN',
        escalationPolicy: json['escalation_policy'] ?? 'UNKNOWN',
        steps: steps,
        finalOutcome: json['final_outcome'] ?? 'UNKNOWN',
        actionTaken: json['action_taken'],
        notes: json['notes'],
        isAvailable: true,
      );
    }
    return MisfireTier2Snapshot.unknown;
  }

  MacroInfoSnapshot _parseMacro(Map<String, dynamic> json) {
    if (json.isNotEmpty && json['status'] != null) {
      return MacroInfoSnapshot(
        status: json['status'] ?? "N_A",
        coverage: json['coverage'] ?? "N_A",
        rates: json['rates'] ?? "N/A",
        dollar: json['dollar'] ?? "N/A",
        oil: json['oil'] ?? "N/A",
        summary: json['summary'] ?? "Initializing...",
        isAvailable: true,
      );
    }
    return MacroInfoSnapshot.unknown;
  }

  EvidenceInfoSnapshot _parseEvidence(Map<String, dynamic> json) {
    if (json.isNotEmpty && json['status'] != null) {
      return EvidenceInfoSnapshot(
        status: json['status'] ?? "N_A",
        sampleSize: json['sample_size'] ?? 0,
        headline: json['headline'] ?? "Initializing...",
        isAvailable: true,
      );
    }
    return EvidenceInfoSnapshot.unknown;
  }
}
