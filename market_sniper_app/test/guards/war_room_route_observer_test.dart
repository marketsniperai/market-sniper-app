import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sniper_app/config/app_config.dart';
import 'package:market_sniper_app/guards/war_room_route_observer.dart';

void main() {
  group('WarRoomRouteObserver Tests', () {
    late WarRoomRouteObserver observer;

    setUp(() {
      observer = WarRoomRouteObserver();
      AppConfig.setWarRoomActive(false); // Reset
    });

    testWidgets('Entering /war_room activates War Room mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          initialRoute: '/',
          routes: {
            '/': (context) => const SizedBox(),
            '/war_room': (context) => const SizedBox(),
          },
        ),
      );

      expect(AppConfig.isWarRoomActive, false);

      // Push War Room
      testNavigator(tester).pushNamed('/war_room');
      await tester.pumpAndSettle();

      expect(AppConfig.isWarRoomActive, true);
    });

    testWidgets('Leaving /war_room deactivates War Room mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          initialRoute: '/',
          routes: {
            '/': (context) => const SizedBox(),
            '/war_room': (context) => const SizedBox(),
          },
        ),
      );

      // Push War Room
      testNavigator(tester).pushNamed('/war_room');
      await tester.pumpAndSettle();
      expect(AppConfig.isWarRoomActive, true);

      // Pop War Room
      testNavigator(tester).pop();
      await tester.pumpAndSettle();
      expect(AppConfig.isWarRoomActive, false);
    });
  });
}

NavigatorState testNavigator(WidgetTester tester) {
  return tester.state(find.byType(Navigator));
}
