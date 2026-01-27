import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/dashboard_payload.dart';
import '../models/context_payload.dart';
import '../models/system_health.dart';

class ApiClient {
  final String baseUrl;
  final http.Client client;

  ApiClient({http.Client? client})
      : baseUrl = AppConfig.apiBaseUrl,
        client = client ?? http.Client();

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (AppConfig.isFounderBuild) {
      headers['X-Founder-Key'] = 'FOUNDER_V0';
    }
    return headers;
  }

  Future<DashboardPayload> fetchDashboard() async {
    final url = Uri.parse('$baseUrl/dashboard');
    final response = await client.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final jsonEnvelope = json.decode(response.body);
      // Lens Doctrine: Wrapper is guaranteed, but check for safety
      final data = jsonEnvelope['data'];
      return DashboardPayload.fromJson(data);
    } else {
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    }
  }

  Future<ContextPayload> fetchContext() async {
    final url = Uri.parse('$baseUrl/context');
    final response = await client.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final jsonEnvelope = json.decode(response.body);
      final data = jsonEnvelope['data'];
      return ContextPayload.fromJson(data);
    } else {
      throw Exception('Failed to load context: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchHealth() async {
    final url = Uri.parse('$baseUrl/health_ext');
    final response = await client.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {};
  }

  Future<Map<String, dynamic>> fetchHealthExt() async {
    final url = Uri.parse('$baseUrl/health_ext');
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchOsHealth() async {
    final url = Uri.parse('$baseUrl/lab/os/health');
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }

  Future<SystemHealth> fetchSystemHealth() async {
    final url = Uri.parse('$baseUrl/misfire');
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return SystemHealth.fromJson(json.decode(response.body));
      } else {
        return SystemHealth.unavailable('HTTP ${response.statusCode}');
      }
    } catch (e) {
      return SystemHealth.unavailable(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchAutofixStatus() async {
    final url = Uri.parse('$baseUrl/lab/autofix/status');
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
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {'status': 'N_A'};
  }

  Future<Map<String, dynamic>> fetchEvidenceSummary() async {
    final url = Uri.parse('$baseUrl/evidence_summary');
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {'status': 'N_A'};
  }

  Future<Map<String, dynamic>> fetchHousekeeperStatus() async {
    final url = Uri.parse('$baseUrl/lab/housekeeper/status');
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
      {String tier = "FREE", bool allowStale = false}) async {
    final uri =
        Uri.parse('$baseUrl/on_demand/context').replace(queryParameters: {
      'ticker': ticker,
      'tier': tier,
      'allow_stale': allowStale.toString(),
    });

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
    try {
      final response = await client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {};
  }
}
