import '../services/api_client.dart';

class RegimeRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> fetchProjectionReport(String symbol) async {
    return _api.fetchProjectionReport(symbol);
  }
}
