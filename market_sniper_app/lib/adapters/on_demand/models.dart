
// Pure Dart models for On-Demand UI adaptation.
// No Flutter imports allowed.

enum AdapterReliabilityState { high, medium, low, calibrating }
enum AdapterSentiment { bullish, bearish, neutral, unknown }
enum AdapterActivityState { active, offline, calibrating, stub }

class OnDemandViewModel {
  final TimeTravellerModel chart;
  final ReliabilityModel reliability;
  final IntelDeckModel intel;
  final TacticalModel tactical;
  final bool isStale;
  final bool isPolicyCached;
  final AttributionModel? attribution;

  const OnDemandViewModel({
    required this.chart,
    required this.reliability,
    required this.intel,
    required this.tactical,
    this.isStale = false,
    this.isPolicyCached = false,
    this.attribution,
  });

  // Safe fallback for empty state
  factory OnDemandViewModel.empty() {
    return const OnDemandViewModel(
      chart: TimeTravellerModel(past: [], future: [], isCalibrating: true),
      reliability: ReliabilityModel(state: AdapterReliabilityState.calibrating, activeInputs: 0),
      intel: IntelDeckModel(
        evidence: IntelCardModel(title: "PROBABILITY ENGINE", lines: [], state: AdapterActivityState.calibrating),
        news: IntelCardModel(title: "CATALYST RADAR", lines: [], state: AdapterActivityState.offline),
        regime: IntelCardModel(title: "REGIME & STRUCTURE", lines: [], state: AdapterActivityState.stub),
      ),
      tactical: TacticalModel(watch: [], invalidate: [], isCalibrating: true),
    );
  }
}

class TimeTravellerModel {
  final List<AdapterCandle> past;
  final List<AdapterCandle> future;
  final bool isCalibrating;

  const TimeTravellerModel({
    required this.past,
    required this.future,
    this.isCalibrating = false,
  });
}

class AdapterCandle {
  final double o;
  final double h;
  final double l;
  final double c;
  final bool isGhost;

  const AdapterCandle({
    required this.o,
    required this.h,
    required this.l,
    required this.c,
    this.isGhost = false,
  });
}

class ReliabilityModel {
  final AdapterReliabilityState state;
  final int? sampleSize;
  final String driftState;
  final int activeInputs;
  final int totalInputs;

  const ReliabilityModel({
    required this.state,
    this.sampleSize,
    this.driftState = "N/A",
    required this.activeInputs,
    this.totalInputs = 4,
  });
}

class IntelDeckModel {
  final IntelCardModel evidence;
  final IntelCardModel news;
  final IntelCardModel regime;

  const IntelDeckModel({
    required this.evidence,
    required this.news,
    required this.regime,
  });
}

class IntelCardModel {
  final String title;
  final List<String> lines;
  final AdapterActivityState state;
  final AdapterSentiment sentiment; // For accent color

  const IntelCardModel({
    required this.title,
    required this.lines,
    required this.state,
    this.sentiment = AdapterSentiment.neutral,
  });
}

class TacticalModel {
  final List<String> watch;
  final List<String> invalidate;
  final bool isCalibrating;

  const TacticalModel({
    required this.watch,
    required this.invalidate,
    this.isCalibrating = false,
  });
}

// D48.BRAIN.02 Attribution
class AttributionModel {
  final String generatedAtUtc;
  final String sourceLadderUsed;
  final List<InputConsulted> inputs;
  final List<String> rules;
  final List<String> facts;
  final List<BlurPolicy> blurPolicies;

  const AttributionModel({
    required this.generatedAtUtc,
    required this.sourceLadderUsed,
    required this.inputs,
    required this.rules,
    required this.facts,
    required this.blurPolicies,
  });
}

class InputConsulted {
  final String engine;
  final String status;

  const InputConsulted(this.engine, this.status);
}

class BlurPolicy {
  final String surface;
  final String reason;
  final String explanation;

  const BlurPolicy({
    required this.surface,
    required this.reason,
    required this.explanation,
  });
}
