import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:market_sniper_app/config/app_config.dart';
import 'package:market_sniper_app/services/api_client.dart';

void main() {
  test('SSOT Enforcement: Blocks legacy calls in War Room', () async {
    // Setup Mock Client
    final mockClient = MockClient((request) async {
      // Return minimal valid payload for fetchDashboard
      return http.Response('{"payload": {}, "status": "OK"}', 200);
    });

    final api = ApiClient(client: mockClient);

    // 1. Activate War Room
    AppConfig.setWarRoomActive(true);
    print("TEST: War Room Active = true");

    // 2. Test Forbidden: fetchDashboard
    print("TEST: Verifying fetchDashboard is BLOCKED...");
    expect(
      () async => await api.fetchDashboard(),
      throwsA(isA<WarRoomPolicyException>()),
      reason: "Should block /dashboard in War Room"
    );
    print("TEST: fetchDashboard BLOCKED as expected.");

    // 3. Test Allowed: fetchUnifiedSnapshot
    print("TEST: Verifying fetchUnifiedSnapshot is ALLOWED...");
    try {
      await api.fetchUnifiedSnapshot();
      print("TEST: fetchUnifiedSnapshot ALLOWED.");
    } catch (e) {
      fail("Should ALLOW /lab/war_room/snapshot in War Room, but threw: $e");
    }

    // 4. Test Allowed: postWatchlistLog
    print("TEST: Verifying postWatchlistLog is ALLOWED...");
    try {
      await api.postWatchlistLog({"action": "TEST"});
      print("TEST: postWatchlistLog ALLOWED.");
    } catch (e) {
      fail("Should ALLOW /lab/watchlist/log in War Room, but threw: $e");
    }

    // 5. Deactivate War Room
    print("TEST: Deactivating War Room...");
    AppConfig.setWarRoomActive(false);

    // 6. Test Allowed Legacy (Warning/Audit only)
    print("TEST: Verifying fetchDashboard is ALLOWED (Inactive)...");
    try {
      await api.fetchDashboard();
      print("TEST: fetchDashboard ALLOWED (Inactive).");
    } catch (e) {
      fail("Should ALLOW /dashboard when War Room is INACTIVE, but threw: $e");
    }
    
    print("TEST: SSOT Enforcement VERIFIED.");
  });
}
