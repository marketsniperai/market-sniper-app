import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sniper_app/screens/war_room_screen.dart';
import 'package:market_sniper_app/config/app_config.dart';
import 'package:market_sniper_app/services/api_client.dart';
import 'package:market_sniper_app/repositories/war_room_repository.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('WarRoomScreen Probe Test', (WidgetTester tester) async {
    // Mock SharedPreferences for DisciplineCounterService
    SharedPreferences.setMockInitialValues({});
    
    // We expect log output to console.
    // This test just ensures the screen builds and initState runs without error.
    // We cannot easily assert debugPrint output in a widget test without overriding DebugPrintCallback,
    // but running this test with `flutter test` will show the output in stdout.
    
    // Config is static, so we rely on default values or what's compatible.
    // Probes rely on kDebugMode (true in tests) and AppConfig.isFounderBuild.
    // AppConfig.isFounderBuild checks kDebugMode -> true.
    // So probes SHOULD fire.
    
    await tester.pumpWidget(const MaterialApp(
      home: WarRoomScreen(),
    ));
    
    // Trigger frame
    await tester.pump();
    
    // Probes are async in initState or postFrameCallback. 
    // We wait a bit.
    await tester.pump(const Duration(milliseconds: 500));
    
    // Check for basic widgets to ensure it mounted
    expect(find.byType(WarRoomScreen), findsOneWidget);
  });
}
