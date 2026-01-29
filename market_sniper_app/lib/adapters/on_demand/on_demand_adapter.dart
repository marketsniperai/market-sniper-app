
import 'models.dart';
import '../../logic/standard_envelope.dart'; // Source of truth

/// Adapts StandardEnvelope / Raw Payload into strongly-typed ViewModels.
/// Encapsulates parsing logic to keep UI build methods clean.
class OnDemandAdapter {
  
  static OnDemandViewModel fromEnvelope(StandardEnvelope? envelope) {
    if (envelope == null) return OnDemandViewModel.empty();

    final raw = envelope.rawPayload;
    
    return OnDemandViewModel(
      chart: _parseChart(raw),
      reliability: _parseReliability(envelope),
      intel: _parseIntel(raw),
      tactical: _parseTactical(raw),
      isStale: envelope.status == EnvelopeStatus.stale, // Simple check, UI adds time-based check
      isPolicyCached: raw['policy_block'] == true,
      attribution: _parseAttribution(raw),
    );
  }

  // --- CHART ---
  static TimeTravellerModel _parseChart(Map<String, dynamic> raw) {
    if (!raw.containsKey('series')) {
      return const TimeTravellerModel(past: [], future: [], isCalibrating: true);
    }
    
    final series = raw['series'];
    if (series is! Map) {
      return const TimeTravellerModel(past: [], future: [], isCalibrating: true);
    }

    try {
      final past = _safeList(series['past'])
          .map((e) => _mapCandle(e))
          .whereType<AdapterCandle>() // Filter nulls
          .toList();

      final future = _safeList(series['future'])
          .map((e) => _mapCandle(e))
          .whereType<AdapterCandle>()
          .toList();

      return TimeTravellerModel(
        past: past,
        future: future,
        isCalibrating: false, // We have data structure
      );
    } catch (_) {
      return const TimeTravellerModel(past: [], future: [], isCalibrating: true);
    }
  }

  static AdapterCandle? _mapCandle(dynamic item) {
    if (item is! Map) return null;
    return AdapterCandle(
      o: _toDouble(item['o']),
      h: _toDouble(item['h']),
      l: _toDouble(item['l']),
      c: _toDouble(item['c']),
      isGhost: item['isGhost'] == true,
    );
  }

  // --- RELIABILITY ---
  static ReliabilityModel _parseReliability(StandardEnvelope env) {
    final raw = env.rawPayload;
    
    // 1. Inputs Calculation
    int totalInputs = 4;
    int missingCount = 0;
    if (raw.containsKey('missingInputs')) {
      final missing = raw['missingInputs'];
      if (missing is List) missingCount = missing.length;
    }
    int activeInputs = totalInputs - missingCount;
    if (activeInputs < 0) activeInputs = 0;

    // 2. Sample Size
    int? sampleSize;
    if (raw['inputs'] is Map && raw['inputs']['evidence'] is Map) {
       sampleSize = raw['inputs']['evidence']['sample_size'];
    }

    // 3. State Derivation
    AdapterReliabilityState state = AdapterReliabilityState.calibrating;
    final backendState = raw['state'];

    if (backendState == "OK") {
      if ((sampleSize ?? 0) > 30) {
        state = AdapterReliabilityState.high;
      } else if ((sampleSize ?? 0) > 10) {
        state = AdapterReliabilityState.medium;
      } else {
        state = AdapterReliabilityState.medium; // Default OK
      }
    } else if (backendState == "INSUFFICIENT_DATA" || backendState == "PROVIDER_DENIED") {
      state = AdapterReliabilityState.low;
    } else {
      state = AdapterReliabilityState.calibrating;
    }

    return ReliabilityModel(
      state: state,
      sampleSize: sampleSize,
      activeInputs: activeInputs,
      totalInputs: totalInputs,
    );
  }

  // --- INTEL ---
  static IntelDeckModel _parseIntel(Map<String, dynamic> raw) {
    final inputs = raw['inputs'] as Map<String, dynamic>? ?? {};
    
    // Evidence
    final ev = inputs['evidence'] as Map<String, dynamic>? ?? {};
    final evMetrics = ev['metrics'] as Map<String, dynamic>? ?? {};
    
    List<String> evLines = [];
    AdapterActivityState evState = AdapterActivityState.calibrating;
    AdapterSentiment evSentiment = AdapterSentiment.neutral;

    if (evMetrics.containsKey('win_rate')) {
      final winRate = _toDouble(evMetrics['win_rate']);
      evLines.add("Historical Match: ${(winRate * 100).toStringAsFixed(0)}%");
      
      if (winRate > 0.6) {
        evSentiment = AdapterSentiment.bullish;
      } else if (winRate < 0.4) {
        evSentiment = AdapterSentiment.bearish;
      } else {
        evSentiment = AdapterSentiment.neutral; // Amber/Stale
      }

      if (evMetrics.containsKey('avg_return')) {
         final ret = _toDouble(evMetrics['avg_return']);
         final sign = ret >= 0 ? "+" : "";
         evLines.add("Avg Move: $sign${(ret * 100).toStringAsFixed(2)}%");
      }
      evState = AdapterActivityState.active;
    } else {
      evLines.add("Insufficient historical matches.");
    }

    final evidenceCard = IntelCardModel(
      title: "PROBABILITY ENGINE", 
      lines: evLines, 
      state: evState, 
      sentiment: evSentiment
    );

    // News
    final news = inputs['news'] as Map<String, dynamic>? ?? {};
    final headlines = _safeStringList(news['headlines']);
    
    List<String> newsLines = [];
    AdapterActivityState newsState = AdapterActivityState.offline;
    AdapterSentiment newsSentiment = AdapterSentiment.unknown;

    if (headlines.isNotEmpty) {
      newsLines = headlines.take(2).toList();
      newsState = AdapterActivityState.active;
      newsSentiment = AdapterSentiment.bullish; // Default active color (Cyan) -> Mapped later
    } else {
      newsLines.add("Radar OFFLINE. (Sources: 0)");
    }

    final newsCard = IntelCardModel(
      title: "CATALYST RADAR",
      lines: newsLines,
      state: newsState,
      sentiment: newsSentiment
    );

    // Regime (Macro)
    List<String> macroLines = [];
    String macroStatus = "NEUTRAL";
    final tags = raw['contextTags'] as Map<String, dynamic>? ?? {};
    if (tags['macro'] is Map) {
      final mTags = _safeList(tags['macro']['tags']);
      if (mTags.contains('MACRO_STUB_NEUTRAL')) {
        macroStatus = "NEUTRAL (STUB)";
      }
    }
    macroLines.add("Macro Environment: $macroStatus");
    macroLines.add("Market Structure: BALANCED");
    
    final regimeCard = IntelCardModel(
      title: "REGIME & STRUCTURE",
      lines: macroLines,
      state: AdapterActivityState.stub,
      sentiment: AdapterSentiment.neutral
    );

    return IntelDeckModel(evidence: evidenceCard, news: newsCard, regime: regimeCard);
  }

  // --- TACTICAL ---
  static TacticalModel _parseTactical(Map<String, dynamic> raw) {
    if (!raw.containsKey('tactical')) {
        return const TacticalModel(watch: ["Calibration in progress..."], invalidate: [], isCalibrating: true);
    }
    
    final tac = raw['tactical'];
    if (tac is! Map) {
        return const TacticalModel(watch: ["Calibration in progress..."], invalidate: [], isCalibrating: true);
    }

    final watch = _safeStringList(tac['watch']);
    final invalidate = _safeStringList(tac['invalidate']);
    
    bool isCalibrating = false;
    List<String> finalWatch = watch;
    
    if (watch.isEmpty) {
        finalWatch = ["Calibration in progress..."];
        isCalibrating = true;
    }

    return TacticalModel(
      watch: finalWatch, 
      invalidate: invalidate.isEmpty ? ["--"] : invalidate, 
      isCalibrating: isCalibrating
    );
  }

  // --- ATTRIBUTION (D48.BRAIN.02) ---
  static AttributionModel? _parseAttribution(Map<String, dynamic> raw) {
    if (!raw.containsKey('attribution')) return null;
    final attr = raw['attribution'];
    if (attr is! Map) return null;

    return AttributionModel(
      generatedAtUtc: attr['generatedAtUtc']?.toString() ?? '',
      sourceLadderUsed: attr['source_ladder_used']?.toString() ?? 'UNKNOWN',
      inputs: _safeList(attr['inputs_consulted']).map((e) {
          if (e is Map) return InputConsulted(e['engine']?.toString() ?? '', e['status']?.toString() ?? '');
          return const InputConsulted('', '');
      }).toList(),
      rules: _safeStringList(attr['rules_fired']),
      facts: _safeStringList(attr['derived_facts']),
      blurPolicies: _safeList(attr['blur_reasons']).map((e) {
          if (e is Map) return BlurPolicy(
              surface: e['surface']?.toString() ?? '', 
              reason: e['reason']?.toString() ?? '', 
              explanation: e['explanation']?.toString() ?? ''
          );
          return const BlurPolicy(surface: '', reason: '', explanation: '');
      }).toList(),
    );
  }

  // Helpers
  static double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static List<dynamic> _safeList(dynamic val) {
    if (val is List) return val;
    return [];
  }

  static List<String> _safeStringList(dynamic val) {
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return [];
  }
}
