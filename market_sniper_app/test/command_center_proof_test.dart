
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sniper_app/screens/command_center_screen.dart';
import 'package:market_sniper_app/widgets/command_center/coherence_quartet_card.dart';
import 'package:market_sniper_app/widgets/command_center/market_pressure_orb.dart';
import 'package:market_sniper_app/services/command_center/discipline_counter_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Command Center Renders Quartet and Market Tilt', (WidgetTester tester) async {
    // Setup SharedPreferences for DisciplineCounterService
    SharedPreferences.setMockInitialValues({});
    
    // Pump Widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CommandCenterScreen()),
      ),
    );

    // Initial Loading State
    await tester.pump(); 
    
    // Wait for FutureBuilder/Async logic (Discipline init + Builder)
    // We might need to settle.
    // Wait for initial build. Don't use pumpAndSettle because Orb has infinite animation.
    await tester.pump(const Duration(seconds: 1));

    // Verify debug logs (These print to console, we will see them in test output)
    debugPrint("TEST_PROOF: Checking Widgets...");

    // Find CoherenceQuartetCard
    final quartetFinder = find.byType(CoherenceQuartetCard);
    expect(quartetFinder, findsOneWidget, reason: "Coherence Quartet should be visible");
    debugPrint("TEST_PROOF: Found Coherence Quartet");

    // Find MarketPressureOrb
    final tiltFinder = find.byType(MarketPressureOrb);
    expect(tiltFinder, findsOneWidget, reason: "Market Pressure Orb should be visible");
    debugPrint("TEST_PROOF: Found Market Pressure Orb");

    // Verify Vertical Order (Tilt below Quartet)
    final quartetPosition = tester.getBottomLeft(quartetFinder);
    final tiltPosition = tester.getTopLeft(tiltFinder);
    
    debugPrint("TEST_PROOF: Quartet Bottom: ${quartetPosition.dy}");
    debugPrint("TEST_PROOF: Tilt Top: ${tiltPosition.dy}");

    expect(tiltPosition.dy, greaterThanOrEqualTo(quartetPosition.dy), reason: "Market Tilt must be below Quartet");
  });
}
