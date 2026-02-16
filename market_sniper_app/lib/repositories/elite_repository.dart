import '../services/api_client.dart';

class EliteRepository {
  static final EliteRepository _instance = EliteRepository._internal();
  factory EliteRepository() => _instance;
  EliteRepository._internal();

  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> fetchEliteRitual(String ritualId) async {
    return _api.fetchEliteRitual(ritualId);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    if (endpoint == '/elite/settings') {
      return _api.postEliteSettings(body);
    }
    if (endpoint == '/elite/reflection') {
      return _api.postEliteReflection(body);
    }
    throw Exception("EliteRepository: Unknown POST endpoint $endpoint");
  }

  Future<List<dynamic>> getEvents({String? since}) async {
    return _api.fetchEliteEvents(since: since);
  }

  Future<Map<String, dynamic>> getEliteState() async {
    return _api.fetchEliteState();
  }

  Future<Map<String, dynamic>> fetchEliteExplainStatus() async {
    return _api.fetchEliteExplainStatus();
  }

  Future<Map<String, dynamic>> fetchEliteOsSnapshot() async {
    return _api.fetchEliteOsSnapshot();
  }

  Future<Map<String, dynamic>> fetchEliteFirstInteractionScript() async {
    return _api.fetchEliteFirstInteractionScript();
  }

  Future<Map<String, dynamic>> sendChatMessage(String message, Map<String, dynamic> context) async {
    // Write operation - delegates to ApiClient
    // ApiClient must handle the endpoint
    return _api.post('/elite/chat', {
       "message": message,
       "context": context
    });
  }

  Future<Map<String, dynamic>> fetchEliteMicroBriefingOpen() async {
    return _api.fetchEliteMicroBriefingOpen();
  }
}
