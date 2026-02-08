import 'dart:async';
import 'package:flutter/foundation.dart';
import 'capital_activity_provider.dart';
import 'mock_capital_activity_provider.dart';

// Dev Flag: Can be overridden via --dart-define=EXTERNAL_SUPPORT_MOCK=true
const bool _kForceMock = bool.fromEnvironment('EXTERNAL_SUPPORT_MOCK', defaultValue: false);

class CapitalActivityRepository {
  final CapitalActivityProvider _mockProvider = MockCapitalActivityProvider();
  
  // Future: Real provider
  // final CapitalActivityProvider _liveProvider; 
  
  // In-Memory Cache (Symbol -> Result)
  final Map<String, CapitalActivityResult> _cache = {};

  Future<CapitalActivityResult> getActivity(String symbol) async {
    // 1. Check Cache
    if (_cache.containsKey(symbol)) {
      return _cache[symbol]!;
    }

    // 2. Select Provider
    // Policy: Default to Unplugged unless Mock forced or Live ready (future)
    CapitalActivityResult result;
    
    if (_kForceMock) {
      // Debug Mode: Fetch Mock
      try {
        result = await _mockProvider.fetchActivity(symbol);
      } catch (e) {
        debugPrint("MOCK_FAIL: $e");
        result = CapitalActivityResult.unplugged();
      }
    } else {
      // Default / Production Safe Mode: Unplugged
      // No external calls. No keys.
      result = CapitalActivityResult.unplugged(); 
    }

    // 3. Cache & Return
    _cache[symbol] = result;
    return result;
  }
}
