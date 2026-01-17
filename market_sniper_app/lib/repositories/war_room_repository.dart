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

  Future<WarRoomSnapshot> fetchSnapshot() async {
    // Parallel fetch
    final results = await Future.wait([
      healthRepo.fetchUnifiedHealth(), // OS Health
      api.fetchAutofixStatus(), // Autopilot
      api.fetchHousekeeperStatus(), // Housekeeper
      api.fetchMisfireStatus(), // Misfire
      api.fetchIronStatus(), // Iron OS
      api.fetchUniverse(), // Universe (Primary)
      api.fetchHealthExt(), // Universe (Fallback source for manifest)
      api.fetchIronTimeline(), // Iron OS Timeline (D41.02)
      api.fetchIronHistory(), // Iron OS History (D41.07)
      api.fetchIronLKG(), // Iron OS LKG (D41.09)
      api.fetchIronDecisionPath(), // Iron OS Decision Path (D41.10)
      api.fetchIronDrift(), // Iron OS Drift (D41.08)
      api.fetchIronReplayIntegrity(), // Iron OS Replay Integrity (D41.11)
      api.fetchLockReason(), // Lock Reason (D42.01)
      api.fetchCoverage(), // Coverage (D42.02)
      api.fetchFindings(), // Findings (D42.08)
      api.fetchBeforeAfterDiff(), // Before/After Diff (D42.09)
    ]);

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
      findings: (await _parseFindingsWrapper(findingsJson)) ?? FindingsSnapshot.unknown,
      universe: _parseUniverse(universeJson, healthJson),
      beforeAfterDiff: await _parseBeforeAfterDiff(diffJson),
    );
  }
  
  Future<BeforeAfterDiffSnapshot?> _parseBeforeAfterDiff(Map<String, dynamic> json) async {
       if (json.isNotEmpty) {
           return BeforeAfterDiffSnapshot.fromJson(json);
       }
       return null;
  }
  
  Future<FindingsSnapshot?> _parseFindingsWrapper(Map<String, dynamic> json) async {
      if (json.isEmpty) return null;
      if (json.containsKey("findings")) {
          return FindingsSnapshot.fromJson(json);
      }
      return null;
  }

  AutopilotSnapshot _parseAutopilot(Map<String, dynamic> autofix) {
    if (autofix.isNotEmpty) {
      final mode = autofix['mode'] ?? (autofix['enabled'] == true ? 'ON' : 'OFF');
      // If legacy 'dial' exists, prefer that (or prioritize mode if consistent)
      // Note: Keeping fallback for safety
      final effectiveMode = autofix['dial'] ?? mode;
      
      return AutopilotSnapshot(
        mode: effectiveMode,
        stage: autofix['stage'] ?? 'IDLE',
        lastAction: autofix['last_action'] ?? 'None',
        lastActionTime: autofix['last_execution_at'] ?? autofix['last_recommendation_at'] ?? '',
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
      return HousekeeperSnapshot(
        autoRun: json['autorun_enabled'] ?? false,
        lastRun: json['last_run_timestamp'] ?? json['last_run_at'] ?? 'NEVER',
        result: json['last_result'] ?? 'UNKNOWN', 
        cooldown: json['cooldown_seconds_remaining'] ?? 0,
        source: "/lab/housekeeper/status",
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
       final events = list.map((e) => IronTimelineEvent(
         timestamp: e['timestamp_utc'] ?? 'N/A',
         type: e['type'] ?? 'UNKNOWN',
         source: e['source'] ?? 'UNKNOWN',
         summary: e['summary'] ?? '-',
       )).toList();

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
       final entries = list.map((e) => IronStateHistoryEntry(
         state: e['state'] ?? 'UNKNOWN',
         timestamp: e['timestamp_utc'] ?? 'N/A',
         source: e['source'] ?? 'UNKNOWN',
       )).toList();

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
        final list = (json['drift'] as List).map((e) => DriftEntry(
           component: e['component'] ?? 'UNKNOWN',
           expected: e['expected'] ?? '',
           observed: e['observed'] ?? '',
           timestamp: e['timestamp_utc'] ?? '',
        )).toList();
        
        return DriftSnapshot(entries: list, source: "/lab/os/iron/drift", isAvailable: true);
     }
     
     return const DriftSnapshot(
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
        final list = (json['entries'] as List).map((e) => CoverageEntry(
           capability: e['capability'] ?? 'UNKNOWN',
           status: e['status'] ?? 'UNAVAILABLE',
           reason: e['reason'],
        )).toList();
        
        return CoverageSnapshot(entries: list, source: "/lab/os/self_heal/coverage", isAvailable: true);
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

  UniverseSnapshot _parseUniverse(Map<String, dynamic> json, Map<String, dynamic> fallback) {
    // Priority 1: /universe JSON (if implemented)
    if (json.isNotEmpty) {
       return UniverseSnapshot(
         status: json['status'] ?? 'LIVE',
         core: json['core_universe'] ?? 'CORE20',
         extended: json['extended_enabled'] == true ? "ON" : "OFF",
         overlayState: json['overlay_state'] ?? 'LIVE',
         overlayAge: json['overlay_age_seconds'] ?? 0,
         source: "/universe",
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
         isAvailable: true,
       );
    }

    return const UniverseSnapshot(
      status: "UNAVAILABLE",
      core: "UNKNOWN",
      extended: "UNKNOWN",
      overlayState: "UNAVAILABLE",
      overlayAge: 0,
      source: "MISSING",
      isAvailable: false,
    );
  }
}
