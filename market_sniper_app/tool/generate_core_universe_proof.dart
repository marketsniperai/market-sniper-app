// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:market_sniper_app/domain/universe/core20_universe.dart';

void main() {
  print("Generating Validation Proof (D39.01C)...");

  final inputs = <String>[
    "SPX", "spx", // Standard
    "BTC", "BTCUSD", "X:BTCUSD", // Aliases
    "VIX", // Restored
    "US2Y", "US02Y", "us02y", // US2Y should now PASS (Restored)
    "AAPL", "UNKNOWN" // Invalid
  ];

  final results = <String, dynamic>{};

  for (final input in inputs) {
    results[input] = {
      "normalized": CoreUniverse.normalizeSymbol(input),
      "isCore20": CoreUniverse.isCore20(input),
      "canonical": CoreUniverse.getDefinition(input)?.symbol,
    };
  }
  
  // Verify Core20 Count
  final distinctSymbols = CoreUniverse.definitions.map((d) => d.symbol).toSet();
  final count = distinctSymbols.length;
  
  final proof = {
    "timestamp": DateTime.now().toIso8601String(),
    "core20_symbol_count": count,
    "inputs": inputs,
    "results": results,
    "compliance": count == 21 ? "PASS_USER_OVERRIDE_21" : "FAIL_COUNT_MISMATCH"
  };

  final outputJson = const JsonEncoder.withIndent('  ').convert(proof);
  print("Proof: \n$outputJson");

  // Write to artifacts (assumes run from repo root)
  const path = 'outputs/runtime/day_39/day_39_01D_core_universe_validator_proof.json';
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(outputJson);
  print("\nWritten to $path");

  if (count != 21) {
    print("FATAL: Core20 count validation failed. Expected 21, got $count");

    exit(1);
  }
}
