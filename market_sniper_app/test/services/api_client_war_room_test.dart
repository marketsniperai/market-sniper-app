import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:market_sniper_app/config/app_config.dart';
import 'package:market_sniper_app/services/api_client.dart';
import 'package:market_sniper_app/models/system_health.dart';

void main() {
  group('ApiClient War Room Policy Tests', () {
    late ApiClient api;

    setUp(() {
       AppConfig.setWarRoomActive(false);
    });

    test('Allowed call: fetchUnifiedSnapshot when Active', () async {
      AppConfig.setWarRoomActive(true);
      
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/lab/war_room/snapshot')) {
           return http.Response('{"modules": {}}', 200);
        }
        return http.Response('Not Found', 404);
      });

      api = ApiClient(client: mockClient);
      final result = await api.fetchUnifiedSnapshot();
      expect(result, isA<Map<String, dynamic>>());
    });

    test('Blocked call: fetchSystemHealth when Active calls /misfire', () async {
      AppConfig.setWarRoomActive(true);
      
      final mockClient = MockClient((request) async {
        return http.Response('OK', 200);
      });

      api = ApiClient(client: mockClient);
      
      // Should NOT call network, but return Unavailable stub
      final result = await api.fetchSystemHealth();
      
      expect(result.status, 'UNAVAILABLE');
      expect(result.reason, contains('WAR_ROOM_POLICY'));
    });

    test('Blocked call: fetchDashboard throws WarRoomPolicyException internally and rethrows', () async {
      AppConfig.setWarRoomActive(true);
      final mockClient = MockClient((request) async => http.Response('OK', 200));
      api = ApiClient(client: mockClient);

      expect(
        () async => await api.fetchDashboard(),
        throwsA(isA<WarRoomPolicyException>()),
      );
    });
  });
}
