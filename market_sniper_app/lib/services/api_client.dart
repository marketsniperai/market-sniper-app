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
}
