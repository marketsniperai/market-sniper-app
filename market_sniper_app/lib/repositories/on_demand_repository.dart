import '../services/api_client.dart';

class OnDemandRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> fetchContext(String ticker,
      {String tier = "FREE", String timeframe = "DAILY", bool allowStale = false}) async {
    return _api.fetchOnDemandContext(ticker, tier: tier, timeframe: timeframe, allowStale: allowStale);
  }
}
