
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<Map<String, dynamic>> fetchEliteRitual(String ritualId) async {
    // D49.HF01: Use Canonical Path (Envelope Response)
    final url = Uri.parse('${AppConfig.apiBaseUrl}/elite/ritual/$ritualId');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        // D49: Returns Envelope { status: "OK", payload: {...} }
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
         throw Exception("ERROR: Server returned ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("CONNECTION ERROR: $e");
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    try {
      final response = await http.post(
        url, 
        headers: {"Content-Type": "application/json"},
        body: json.encode(body)
      ).timeout(const Duration(seconds: 15)); // Longer timeout for LLM

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Server ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  Future<List<dynamic>> getEvents({String? since}) async {
    String url = '${AppConfig.apiBaseUrl}/events/latest';
    if (since != null) {
       url += '?since=$since';
    }
    
    try {
       final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
       if (response.statusCode == 200) {
          final data = json.decode(response.body);
          // Expect { "events": [...] }
          return data['events'] as List<dynamic>;
       }
       return [];
    } catch (_) {
       return [];
    }
  }


  Future<Map<String, dynamic>> getEliteState() async {
    try {
        final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/elite/state'));
        if (response.statusCode == 200) {
            return json.decode(response.body) as Map<String, dynamic>;
        }
    } catch (_) {}
    return {};
  }
}

