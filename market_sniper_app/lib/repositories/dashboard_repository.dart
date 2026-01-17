import '../models/dashboard_payload.dart';
import '../services/api_client.dart';

class DashboardRepository {
  final ApiClient _api;

  // D37.01: Centralized configuration for freshness
  // Though logic is currently in model, repository is the fetching authority.
  
  DashboardRepository({ApiClient? api}) : _api = api ?? ApiClient();

  /// Fetches the Single Source of Truth dashboard artifact.
  /// Bubbles exceptions to be handled by the UI/Block logic.
  Future<DashboardPayload> fetchDashboard() async {
    try {
      // D37.01: Direct usage of existing logic, but wrapped for future caching/logic
      return await _api.fetchDashboard();
    } catch (e) {
      // Future scope: specific error mapping
      rethrow;
    }
  }
}
