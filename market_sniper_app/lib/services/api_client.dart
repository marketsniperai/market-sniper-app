import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import '../config/app_config.dart';
import '../models/dashboard_payload.dart';
import '../models/context_payload.dart';
import '../models/system_health.dart';

class WarRoomPolicyException implements Exception {
  final String message;
  final String path;
  WarRoomPolicyException(this.message, this.path);
  @override
  String toString() => "WarRoomPolicyException: $message ($path)";
}

class ApiClient {
  // D73: Snapshot Only Policy Enforcer
  void _checkSnapshotPolicy(String endpoint) {
    if (AppConfig.isSnapshotOnlyMode) {
      throw WarRoomPolicyException("Legacy Endpoint Blocked", endpoint);
    }
  }


  // ... (Apply to other methods: system_health, universe, options, macro, news, etc.)
  // I will use multi_replace for this to cover all methods efficiently.

  final String baseUrl;
  final http.Client client;

  ApiClient({http.Client? client})
      : baseUrl = AppConfig.apiBaseUrl,
        client = client ?? http.Client();

  // ... (headers get omitted for brevity if unchanged, but I need to include context to replace correctly) 
  // Wait, I can't lookahead lines I haven't seen in ReplaceFileContent unless I replace the whole block.
  // I will replace likely from class start or helper method.
  
  Map<String, String> get _headers {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // D62.0 HOTFIX: Allow Founder Key on Remote/Web if Founder Build
      if (kIsWeb && kDebugMode && AppConfig.isFounderBuild) {
         final key = AppConfig.founderApiKey;
         if (key.isNotEmpty) {
            // WEB_LAB_AUTH: sending founder header
            debugPrint("WEB_LAB_AUTH: sending founder header = true, keyHashPrefix=${key.substring(0, 5)}...");
            headers['X-Founder-Key'] = key;
         }
      } else if (kDebugMode && AppConfig.isFounderBuild) {
         // Existing Logic for Mobile/Local
         final key = AppConfig.founderApiKey;
         if (key.isNotEmpty && baseUrl.contains('localhost')) {
            headers['X-Founder-Key'] = key;
         }
      }
      return headers;
  }

  void _audit(String method, Uri url) {
    // D56.01.5: Network Audit (Snapshot-Only Enforcement)
    final path = url.path;
    
    // GUARD: If War Room is ACTIVE, strictly forbid any non-Snapshot traffic.
    // BOARDING PASS (D56.01.5: War Room Strict SSOT)
    if (AppConfig.isWarRoomActive) {
        // ALLOW-LIST
        bool isAllowed = false;

        // 1. USP-1 Core
        if (path.contains('/lab/war_room/snapshot')) isAllowed = true;
        
        // 2. Writes (Logging/Telemetry)
        // Allowed as they don't violate Read-SSOT
        if (path.contains('/lab/watchlist/log')) isAllowed = true;

        if (!isAllowed) {
            final msg = "WAR_ROOM_POLICY: BLOCKED legacy call to $path";
            if (AppConfig.isNetAuditEnabled) debugPrint(msg);
            // Safe Deny: Throw controlled exception
            throw WarRoomPolicyException("Legacy Network Call Blocked in War Room", path);
        }
    }

    if (!kDebugMode) return;
    // Further Check for Audit Toggle
    if (!AppConfig.isNetAuditEnabled) return;
    
    final isAllowed = path.contains('/lab/war_room/snapshot');
    
    // D56.01.6: Full URL Visibility
    final fullLog = "baseUrl=$baseUrl path=$path full=${url.toString()}";

    if (isAllowed) {
      debugPrint("NET_AUDIT: [ALLOW] $method $path ($fullLog)");
    } else {
      debugPrint("NET_AUDIT: [SUSPECT] $method $path (Legacy Call Detected) ($fullLog)");
    }
  }

  Future<DashboardPayload> fetchDashboard() async {
    _checkSnapshotPolicy('/dashboard');
    final url = Uri.parse('$baseUrl/dashboard');
    try {
        _audit('GET', url);
        final response = await client.get(url, headers: _headers);

        if (response.statusCode == 200) {
          final jsonEnvelope = json.decode(response.body);
          // D62.10: PROD Schema Fix. Response has 'payload', not 'data'.
          // We check both for backward compat, but 'payload' is canonical 1.0.
          final data = jsonEnvelope['payload'] ?? jsonEnvelope['data'];
          
          if (data == null) {
             throw Exception('Dashboard payload is null');
          }
          if (data is! Map<String, dynamic>) {
             throw Exception('Dashboard payload is not a Map');
          }
          
          return DashboardPayload.fromJson(data);
        } else {
          throw Exception('Failed to load dashboard: ${response.statusCode}');
        }
    } on WarRoomPolicyException {
        // Safe Deny: Return Empty/Unavailable Dashboard Logic
        // DashboardPayload doesn't have a clean 'empty' factory, so we rethrow 
        // OR we return a dummy if feasible. 
        // User Requirement: "safe deny behavior... OR a controlled error that is ALWAYS caught inside repositories"
        // Since DashboardScreen handles errors, rethrowing WarRoomPolicyException 
        // (which is an Exception) serves the "Safe Deny" as long as it doesn't crash the APP.
        // Dashboard loading handles exceptions.
        rethrow;
    }
  }

  // ... fetchContext ...

  Future<SystemHealth> fetchSystemHealth() async {
    final url = Uri.parse('$baseUrl/misfire');
    try {
        _checkSnapshotPolicy('/misfire'); // Legacy alias
        _audit('GET', url);
        final response = await client.get(url, headers: _headers);
        if (response.statusCode == 200) {
          return SystemHealth.fromJson(json.decode(response.body));
        } else {
          return SystemHealth.unavailable('HTTP ${response.statusCode}');
        }
    } on WarRoomPolicyException catch (e) {
        // Safe Deny: Return Unavailable Stub
        // This PREVENTS crashes and allows UI to show "Unavailable" state gracefully.
        return SystemHealth.unavailable("WAR_ROOM_POLICY: ${e.message}");
    } catch (e) {
      return SystemHealth.unavailable(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchAutofixStatus() async {
    _checkSnapshotPolicy('/autofix');
    // REWIRED: Ghost /lab/autofix/status -> Canonical /autofix (Day 15)
    final url = Uri.parse('$baseUrl/autofix');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {'status': 'UNAVAILABLE'};
  }

  Future<Map<String, dynamic>> fetchAutoFixTier1Status() async {
    _checkSnapshotPolicy('/lab/os/self_heal/autofix/tier1/status');
    final url = Uri.parse('$baseUrl/lab/os/self_heal/autofix/tier1/status');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchAutoFixDecisionPath() async {
    _checkSnapshotPolicy('/lab/os/self_heal/autofix/decision_path');
    final url = Uri.parse('$baseUrl/lab/os/self_heal/autofix/decision_path');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }



  Future<Map<String, dynamic>> fetchSelfHealConfidence() async {
    // STUB: Deep Dive not yet implemented.
    return {'status': 'UNAVAILABLE', 'score': 0.0};
  }

  Future<Map<String, dynamic>> fetchSelfHealWhatChanged() async {
    // STUB: Deep Dive not yet implemented.
    return {'status': 'UNAVAILABLE', 'changes': []};
  }

  Future<Map<String, dynamic>> fetchCooldownTransparency() async {
    // STUB: Deep Dive not yet implemented.
    return {'status': 'UNAVAILABLE', 'active': false};
  }

  Future<Map<String, dynamic>> fetchRedButtonStatus() async {
    // STUB: Deep Dive not yet implemented.
    return {'status': 'UNAVAILABLE', 'active': false};
  }



  Future<Map<String, dynamic>> fetchOptionsContext() async {
    _checkSnapshotPolicy('/options_context');
    final url = Uri.parse('$baseUrl/options_context');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {'status': 'N_A'};
  }

  Future<Map<String, dynamic>> fetchMacroContext() async {
    _checkSnapshotPolicy('/macro_context');
    final url = Uri.parse('$baseUrl/macro_context');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {'status': 'N_A'};
  }

  Future<Map<String, dynamic>> fetchEconomicCalendar() async {
    _checkSnapshotPolicy('/economic_calendar');
    final url = Uri.parse('$baseUrl/economic_calendar');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {'source': 'OFFLINE', 'events': []};
  }

  Future<Map<String, dynamic>> fetchNewsDigest() async {
    _checkSnapshotPolicy('/news_digest');
    final url = Uri.parse('$baseUrl/news_digest');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {'source': 'OFFLINE', 'items': []}; // Safe Fallback
  }

  Future<Map<String, dynamic>> fetchEvidenceSummary() async {
    _checkSnapshotPolicy('/evidence_summary');
    final url = Uri.parse('$baseUrl/evidence_summary');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {'status': 'N_A'};
  }

  Future<Map<String, dynamic>> fetchHousekeeperStatus() async {
    _checkSnapshotPolicy('/lab/os/self_heal/housekeeper/status');
    final url = Uri.parse('$baseUrl/lab/os/self_heal/housekeeper/status');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchIronStatus() async {
    _checkSnapshotPolicy('/lab/os/iron/status');
    final url = Uri.parse('$baseUrl/lab/os/iron/status');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchIronTimeline() async {
    _checkSnapshotPolicy('/lab/os/iron/timeline_tail');
    final url = Uri.parse('$baseUrl/lab/os/iron/timeline_tail');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchIronHistory() async {
    _checkSnapshotPolicy('/lab/os/iron/state_history');
    final url = Uri.parse('$baseUrl/lab/os/iron/state_history');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchIronLKG() async {
    _checkSnapshotPolicy('/lab/os/iron/lkg');
    final url = Uri.parse('$baseUrl/lab/os/iron/lkg');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchIronDecisionPath() async {
    _checkSnapshotPolicy('/lab/os/iron/decision_path');
    final url = Uri.parse('$baseUrl/lab/os/iron/decision_path');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchIronDrift() async {
    _checkSnapshotPolicy('/lab/os/iron/drift');
    final url = Uri.parse('$baseUrl/lab/os/iron/drift');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchIronReplayIntegrity() async {
    _checkSnapshotPolicy('/lab/os/iron/replay_integrity');
    final url = Uri.parse('$baseUrl/lab/os/iron/replay_integrity');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchLockReason() async {
    // STUB: Use Unified Snapshot instead.
    return {'status': 'UNAVAILABLE', 'reason': 'Use Unified Snapshot'};
  }

  Future<Map<String, dynamic>> fetchCoverage() async {
    // STUB: Deep Dive not yet implemented.
    return {'status': 'UNAVAILABLE', 'percent': 0.0};
  }

  Future<Map<String, dynamic>> fetchFindings() async {
    _checkSnapshotPolicy('/lab/os/self_heal/findings');
    final url = Uri.parse('$baseUrl/lab/os/self_heal/findings');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchBeforeAfterDiff() async {
    _checkSnapshotPolicy('/lab/os/self_heal/before_after');
    final url = Uri.parse('$baseUrl/lab/os/self_heal/before_after');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchUniverse() async {
    _checkSnapshotPolicy('/universe');
    final url = Uri.parse('$baseUrl/universe');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchMisfireStatus() async {
    _checkSnapshotPolicy('/misfire');
    final url = Uri.parse('$baseUrl/misfire');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<void> postWatchlistLog(Map<String, dynamic> eventData) async {
    final url = Uri.parse('$baseUrl/lab/watchlist/log');
    try {
       _audit('POST', url);
       // Fire and forget, but we await to ensure network transmission started
       // We don't return anything or throw on error per spec (swallow errors in repo/ledger)
       await client.post(
        url,
        headers: _headers,
        body: json.encode(eventData),
       );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> fetchOnDemandContext(String ticker,
      {String tier = "FREE", String timeframe = "DAILY", bool allowStale = false}) async {
    final uri =
        Uri.parse('$baseUrl/on_demand/context').replace(queryParameters: {
      'ticker': ticker,
      'tier': tier,
      'timeframe': timeframe,
      'allow_stale': allowStale.toString(),
    });
    
    _checkSnapshotPolicy('/on_demand/context');
    _audit('GET', uri);
    // OnDemand is a READ path, it should be subject to policy?
    // User said "All UI read operations MUST originate from UnifiedSnapshotRepository".
    // But OnDemand is likely "On Demand" and might not be in snapshot?
    // "PART V — ... In ApiClient (read methods only): exception in snapshot mode"
    // So if OnDemand is not in snapshot, it's effectively KILLED in snapshot mode.
    // If it is allowed, it must be white-listed.
    // Assuming strictly, it should be blocked.
    _checkSnapshotPolicy('/on_demand/context');
    _audit('GET', uri);

    try {
      final response = await client.get(uri, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 429) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {"status": "UNAVAILABLE", "freshness": "UNAVAILABLE", "payload": {}};
  }

  Future<Map<String, dynamic>> fetchLiveOverlay() async {
    _checkSnapshotPolicy('/overlay_live');
    final url = Uri.parse('$baseUrl/overlay_live');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchHealthExt() async {
    _checkSnapshotPolicy('/health_ext');
    final url = Uri.parse('$baseUrl/health_ext');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchOsHealth() async {
    _checkSnapshotPolicy('/lab/os/health');
    final url = Uri.parse('$baseUrl/lab/os/health');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchUnifiedSnapshot() async {
    final url = Uri.parse('$baseUrl/lab/war_room/snapshot');
    try {
      final response = await client.get(url, headers: _headers);
      return _processResponse(response);
    } catch (e) {
      debugPrint("API_CLIENT: Snapshot Fetch Error: $e");
      rethrow;
    }
  }

  // D73: Total SSOT Migration - Raw Fetch for Repository
  // Whitelisted from blocking policy.
  Future<Map<String, dynamic>> fetchUnifiedSnapshotRaw({bool nocache = false}) async {
    var uri = Uri.parse('$baseUrl/lab/war_room/snapshot');
    if (nocache) {
      uri = uri.replace(queryParameters: {'nocache': '1'});
    }
    
    // NO BLOCKING CHECK HERE - This is the designated survivor.
    
    try {
      final response = await client.get(uri, headers: _headers);
      // We return the raw JSON body (which is the Envelope)
      return _processResponse(response);
    } catch (e) {
      debugPrint("API_CLIENT: SSOT Raw Fetch Error: $e");
      rethrow;
    }
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return {};
      return json.decode(response.body);
    }
    // D55: Fail-Hidden (return empty) or Throw?
    // For USP-1 we might want to know about failures.
    // But basic contract is Map.
    debugPrint("API_CLIENT: Non-200 Response: ${response.statusCode} ${response.request?.url}");
    if (response.statusCode == 404) return {}; 
    throw Exception("API Error: ${response.statusCode}");
  }

  Future<Map<String, dynamic>> fetchWarRoomDashboard() async {
    _checkSnapshotPolicy('/lab/war_room');
    final url = Uri.parse('$baseUrl/lab/war_room');
    _audit('GET', url);
    debugPrint("WARROOM_FETCH url=$url"); 
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        debugPrint("WARROOM_FETCH status=200");
        return json.decode(response.body);
      } else {
        debugPrint("WARROOM_FETCH status=${response.statusCode}");
        if (response.body.isNotEmpty) {
           final trunc = response.body.length > 120 ? response.body.substring(0, 120) : response.body;
           debugPrint("WARROOM_FETCH body_preview=$trunc");
        }
      }
    } catch (e) {
      debugPrint("WARROOM_FETCH Error: $e");
    }
    return {};
  }
  Future<Map<String, dynamic>> fetchProjectionReport(String symbol) async {
    _checkSnapshotPolicy('/projection/report');
    final url = Uri.parse('$baseUrl/projection/report?symbol=$symbol');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }
  // --- ELITE METHODS (Delegated from EliteRepository) ---

  Future<Map<String, dynamic>> fetchEliteRitual(String ritualId) async {
    _checkSnapshotPolicy('/elite/ritual');
    final url = Uri.parse('$baseUrl/elite/ritual/$ritualId');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> postEliteSettings(Map<String, dynamic> body) async {
    _checkSnapshotPolicy('/elite/settings');
    final url = Uri.parse('$baseUrl/elite/settings');
    _audit('POST', url);
    try {
      final response = await client.post(url, headers: _headers, body: json.encode(body));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> postEliteReflection(Map<String, dynamic> body) async {
    _checkSnapshotPolicy('/elite/reflection');
    final url = Uri.parse('$baseUrl/elite/reflection');
    _audit('POST', url);
    try {
      final response = await client.post(url, headers: _headers, body: json.encode(body));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<List<dynamic>> fetchEliteEvents({String? since}) async {
    _checkSnapshotPolicy('/events/latest');
    String urlStr = '$baseUrl/events/latest';
    if (since != null) urlStr += '?since=$since';
    final url = Uri.parse(urlStr);
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['events'] as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> fetchEliteState() async {
    _checkSnapshotPolicy('/elite/state');
    final url = Uri.parse('$baseUrl/elite/state');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchEliteExplainStatus() async {
    _checkSnapshotPolicy('/elite/explain/status');
    final url = Uri.parse('$baseUrl/elite/explain/status');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {'status': 'UNAVAILABLE'};
  }

  Future<Map<String, dynamic>> fetchEliteOsSnapshot() async {
    _checkSnapshotPolicy('/elite/os/snapshot');
    final url = Uri.parse('$baseUrl/elite/os/snapshot');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchEliteFirstInteractionScript() async {
    _checkSnapshotPolicy('/elite/script/first_interaction');
    final url = Uri.parse('$baseUrl/elite/script/first_interaction');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchEliteMicroBriefingOpen() async {
    _checkSnapshotPolicy('/elite/micro_briefing/open');
    final url = Uri.parse('$baseUrl/elite/micro_briefing/open');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }
}

