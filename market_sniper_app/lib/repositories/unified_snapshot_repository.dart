import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../config/app_config.dart';

// D73: Unified Snapshot Envelope (Partial/Full)
class UnifiedSnapshotEnvelope {
  final String status; // LIVE, COMPUTE_ERROR, UNAVAILABLE
  final String asOfUtc;
  final bool partial;
  final List<String> reasonCodes;
  final Map<String, dynamic>? payload; // The raw snapshot data

  UnifiedSnapshotEnvelope({
    required this.status,
    required this.asOfUtc,
    required this.partial,
    required this.reasonCodes,
    this.payload,
  });

  factory UnifiedSnapshotEnvelope.fromJson(Map<String, dynamic> json) {
    return UnifiedSnapshotEnvelope(
      status: json['status'] ?? 'UNKNOWN',
      asOfUtc: json['as_of_utc'] ?? DateTime.now().toIso8601String(),
      partial: json['partial'] ?? false,
      reasonCodes: List<String>.from(json['reason_codes'] ?? []),
      payload: json['payload'], // Can be null
    );
  }
}

// D73: Single Source of Truth Repository
class UnifiedSnapshotRepository {
  // Singleton
  static final UnifiedSnapshotRepository _instance = UnifiedSnapshotRepository._internal();
  factory UnifiedSnapshotRepository() => _instance;
  UnifiedSnapshotRepository._internal();

  final ApiClient _api = ApiClient();

  // In-Memory Cache
  UnifiedSnapshotEnvelope? _lastEnvelope;
  DateTime? _lastFetchUtc;

  UnifiedSnapshotEnvelope? get lastEnvelope => _lastEnvelope;

  // Primary Fetch (SSOT)
  Future<UnifiedSnapshotEnvelope> fetch({bool nocache = false}) async {
    // D73: The ONLY Allowed Read Endpoint
    // We reuse ApiClient BUT ApiClient itself will soon block other calls.
    // We call a specific method on ApiClient that bypasses the block OR uses the allowed endpoint.
    
    // For now, we use the method we will add to ApiClient: fetchUnifiedSnapshot()
    // NOTE: ApiClient must pass "X-Founder-Key" headers logic provided by AppConfig.
    
    try {
      final data = await _api.fetchUnifiedSnapshotRaw(nocache: nocache);
      final envelope = UnifiedSnapshotEnvelope.fromJson(data);
      
      _lastEnvelope = envelope;
      _lastFetchUtc = DateTime.now().toUtc();
      
      if (kDebugMode && AppConfig.isNetAuditEnabled) {
        debugPrint("SSOT_REPO: Fetched Snapshot. Status=${envelope.status} Payload=${envelope.payload != null}");
      }
      
      return envelope;
      
    } catch (e) {
      debugPrint("SSOT_REPO: Fetch Failed: $e");
      // Return a synthesized error envelope so UI doesn't crash
      return UnifiedSnapshotEnvelope(
        status: 'NETWORK_FAIL', 
        asOfUtc: DateTime.now().toIso8601String(), 
        partial: true, 
        reasonCodes: ['NETWORK_ERROR', e.toString()]
      );
    }
  }

  // Convenience Accessors (Safe Decoding)
  // Modules should grab their section from payload or return null if missing
  Map<String, dynamic>? getModule(String moduleKey) {
    if (_lastEnvelope?.payload == null) return null;
    final modules = _lastEnvelope!.payload!['modules'];
    if (modules is! Map) return null;
    return modules[moduleKey];
  }
}
