
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sniper_app/adapters/on_demand/on_demand_adapter.dart';
import 'package:market_sniper_app/adapters/on_demand/models.dart';
import 'package:market_sniper_app/logic/standard_envelope.dart';

void main() {
  test('OnDemandAdapter Smoke Test', () {
    // 1. Load Sample JSON
    final file = File('../outputs/samples/on_demand_context_sample.json');
    if (!file.existsSync()) {
      print("Warning: Sample file not found, skipping deep check.");
      return;
    }
    
    final jsonStr = file.readAsStringSync();
    final Map<String, dynamic> json = jsonDecode(jsonStr);
    
    // 2. Build Envelope
    final envelope = EnvelopeBuilder.build(json);
    
    // 3. Run Adapter
    final vm = OnDemandAdapter.fromEnvelope(envelope);
    
    // 4. Verify VM Properties
    // Chart
    expect(vm.chart.isCalibrating, isNotNull);
    print("Chart Calibrating: ${vm.chart.isCalibrating}");
    print("Past Candles: ${vm.chart.past.length}");
    print("Future Candles: ${vm.chart.future.length}");
    
    // Reliability
    print("Reliability State: ${vm.reliability.state}");
    print("Active Inputs: ${vm.reliability.activeInputs}/${vm.reliability.totalInputs}");
    
    // Intel
    print("Evidence Title: ${vm.intel.evidence.title}");
    print("News Lines: ${vm.intel.news.lines.length}");
    
    // Tactical
    print("Tactical Watch: ${vm.tactical.watch}");
    
    // 5. Assertions
    // Sample should have data
    expect(vm.intel.evidence.title, "PROBABILITY ENGINE");
  });
  
  test('Empty Envelope Handling', () {
     final vm = OnDemandAdapter.fromEnvelope(null);
     expect(vm.chart.isCalibrating, true);
     expect(vm.reliability.state, AdapterReliabilityState.calibrating);
  });
}
