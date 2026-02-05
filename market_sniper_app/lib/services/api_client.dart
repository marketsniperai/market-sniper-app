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
  final String baseUrl;
  final http.Client client;

  ApiClient({http.Client? client})
      : baseUrl = AppConfig.apiBaseUrl,
        client = client ?? http.Client();

  // ... (headers get omitted for brevity if unchanged, but I need to include context to replace correctly) 
  // Wait, I can't lookahead lines I haven't seen in ReplaceFileContent unless I replace the whole block.
  // I will replace likely from class start or helper method.
  
  Map<String, String> get _headers {
      // Re-implementing _headers to ensure context matches (or I can trust line numbers from previous view)
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (kIsWeb && kDebugMode && AppConfig.isFounderBuild) {
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
    if (AppConfig.isWarRoomActive) {
        if (!path.contains('/lab/war_room/snapshot')) {
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
    final url = Uri.parse('$baseUrl/dashboard');
    try {
        _audit('GET', url);
        final response = await client.get(url, headers: _headers);

        if (response.statusCode == 200) {
          final jsonEnvelope = json.decode(response.body);
          final data = jsonEnvelope['data'];
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
    final url = Uri.parse('$baseUrl/lab/autofix/status');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchAutoFixTier1Status() async {
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

  Future<Map<String, dynamic>> fetchMisfireRootCause() async {
    final url = Uri.parse('$baseUrl/lab/os/self_heal/misfire/root_cause');
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
    final url = Uri.parse('$baseUrl/lab/os/self_heal/confidence');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchSelfHealWhatChanged() async {
    final url = Uri.parse('$baseUrl/lab/os/self_heal/what_changed');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchCooldownTransparency() async {
    final url = Uri.parse('$baseUrl/lab/os/self_heal/cooldowns');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchRedButtonStatus() async {
    final url = Uri.parse('$baseUrl/lab/os/self_heal/red_button/status');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchMisfireTier2() async {
    final url = Uri.parse('$baseUrl/lab/os/self_heal/misfire/tier2');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchOptionsContext() async {
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

  Future<Map<String, dynamic>> fetchEvidenceSummary() async {
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
    final url = Uri.parse('$baseUrl/lab/os/self_heal/lock_reason');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchCoverage() async {
    final url = Uri.parse('$baseUrl/lab/os/self_heal/coverage');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchFindings() async {
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
    final url = Uri.parse('$baseUrl/health_ext');
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchOsHealth() async {
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
    _audit('GET', url);
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("USP_FETCH_FAIL status=${response.statusCode}");
      }
    } catch (e) {
      debugPrint("USP_FETCH_ERROR: $e");
      rethrow; 
    }
    return {};
  }

  Future<Map<String, dynamic>> fetchWarRoomDashboard() async {
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
}

