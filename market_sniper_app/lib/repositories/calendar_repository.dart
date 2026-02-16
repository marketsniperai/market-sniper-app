import '../services/api_client.dart';

class CalendarRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> fetchEconomicCalendar() async {
    return _api.fetchEconomicCalendar();
  }
}
