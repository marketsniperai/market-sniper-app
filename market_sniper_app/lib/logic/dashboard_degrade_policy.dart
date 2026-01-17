import '../models/dashboard_payload.dart';
import 'data_state_resolver.dart';

enum DegradeState {
  ok,
  partial,
  stale,
  unavailable,
}

class DegradeContext {
  final DegradeState state;
  final String reasonCode;
  final List<String> missingFields;

  const DegradeContext({
    required this.state,
    required this.reasonCode,
    this.missingFields = const [],
  });
  
  static const DegradeContext ok = DegradeContext(state: DegradeState.ok, reasonCode: "NOMINAL");
}

class DashboardDegradePolicy {
  static DegradeContext evaluate({
    required DashboardPayload? payload,
    required ResolvedDataState dataState,
    required String? fetchError,
  }) {
    // 1. Connectivity / Error
    if (fetchError != null && payload == null) {
      return DegradeContext(
        state: DegradeState.unavailable,
        reasonCode: "FETCH_ERROR: ${fetchError.replaceAll(RegExp(r'\s+'), ' ').trim()}", // Sanitize
      );
    }
    
    // 2. Missing Payload
    if (payload == null) {
      return const DegradeContext(
        state: DegradeState.unavailable,
        reasonCode: "NO_PAYLOAD",
      );
    }

    // 3. Stale State (from Resolver)
    // If Resolver says STALE, we respect it as a degrade state.
    if (dataState.state == DataState.stale) {
      return DegradeContext(
        state: DegradeState.stale,
        reasonCode: "DATA_STALE_${dataState.reason.name.toUpperCase()}",
      );
    }
    
    // 4. Missing Canonical Fields (Partial)
    // Check critical fields. DashboardPayload usually non-nullable fields are required by structure,
    // but values might be empty or fallback defaults.
    // If run_id is "UNKNOWN" or missing artifacts?
    final List<String> missing = [];
    if (payload.runId == "UNKNOWN") missing.add("run_id");
    if (payload.widgets.isEmpty) missing.add("widgets_manifest");
    
    if (missing.isNotEmpty) {
      return DegradeContext(
        state: DegradeState.partial,
        reasonCode: "PARTIAL_DATA",
        missingFields: missing,
      );
    }

    // 5. Nominal
    return DegradeContext.ok;
  }
}
