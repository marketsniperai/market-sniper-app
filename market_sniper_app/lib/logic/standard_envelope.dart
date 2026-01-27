/// Enum representing the standard status of an On-Demand result.
enum EnvelopeStatus { live, stale, locked, unavailable, error }

/// Enum representing the data source.
enum EnvelopeSource { pipeline, cache, offline }

/// Standard confidence badges.
enum ConfidenceBadge { coverage, integrity, providerLive, proxyEstimated }

/// Reason for sanitization.
enum SanitizationReason { bannedPhraseDetected, missingMandatoryData, none }

/// The Standard Envelope for On-Demand results.
class StandardEnvelope {
  final EnvelopeStatus status;
  final DateTime asOfUtc;
  final EnvelopeSource source;
  final List<ConfidenceBadge> confidenceBadges;
  final List<String> bullets;
  final bool sanitized;
  final SanitizationReason sanitizationReason;
  // Payload for raw access if strictly needed (discouraged)
  final Map<String, dynamic> rawPayload;

  StandardEnvelope({
    required this.status,
    required this.asOfUtc,
    required this.source,
    required this.confidenceBadges,
    required this.bullets,
    required this.sanitized,
    this.sanitizationReason = SanitizationReason.none,
    this.rawPayload = const {},
  });
}

/// Builder to adapt raw API responses into a StandardEnvelope.
class EnvelopeBuilder {
  static StandardEnvelope build(Map<String, dynamic> rawResponse) {
    // 1. Map Status
    EnvelopeStatus status;
    final rawStatus =
        (rawResponse["status"] ?? "ERROR").toString().toUpperCase();
    switch (rawStatus) {
      case "LIVE":
        status = EnvelopeStatus.live;
        break;
      case "STALE":
        status = EnvelopeStatus.stale;
        break;
      case "BLOCKED":
        status = EnvelopeStatus.locked;
        break; // Map BLOCKED -> LOCKED
      case "OFFLINE":
        status = EnvelopeStatus.unavailable;
        break;
      case "ERROR":
      default:
        status = EnvelopeStatus.error;
        break;
    }

    // 2. Map Source
    EnvelopeSource source;
    final rawSource =
        (rawResponse["source"] ?? "OFFLINE").toString().toUpperCase();
    switch (rawSource) {
      case "PIPELINE":
        source = EnvelopeSource.pipeline;
        break;
      case "CACHE":
        source = EnvelopeSource.cache;
        break;
      default:
        source = EnvelopeSource.offline;
        break;
    }

    // 3. Map Badges (Heuristic or explicit)
    List<ConfidenceBadge> badges = [];
    if (status == EnvelopeStatus.live) badges.add(ConfidenceBadge.providerLive);
    if (status == EnvelopeStatus.stale) {
      badges.add(ConfidenceBadge.proxyEstimated); // Assumption for stale
    }
    // Could map more from rawResponse["badges"] if available

    // 4. Extract Bullets
    List<String> bullets = [];
    if (rawResponse["payload"] != null &&
        rawResponse["payload"]["bullets"] is List) {
      bullets = List<String>.from(rawResponse["payload"]["bullets"]);
    } else if (rawResponse["bullets"] is List) {
      bullets = List<String>.from(rawResponse["bullets"]);
    }

    // Fallback generation if empty but valid
    if (bullets.isEmpty &&
        status != EnvelopeStatus.error &&
        status != EnvelopeStatus.locked) {
      final globalRisk = rawResponse["payload"]?["global_risk"] ?? "UNKNOWN";
      final regime = rawResponse["payload"]?["regime"] ?? "UNKNOWN";
      bullets.add("Risk State: $globalRisk");
      bullets.add("Regime: $regime");
      bullets.add("Ticker: ${rawResponse['ticker'] ?? 'UNKNOWN'}");
    }

    // 5. Timestamp
    DateTime asOf;
    try {
      asOf = DateTime.parse(
          rawResponse["timestamp_utc"] ?? DateTime.now().toIso8601String());
    } catch (_) {
      asOf = DateTime.now();
    }

    return StandardEnvelope(
      status: status,
      asOfUtc: asOf,
      source: source,
      confidenceBadges: badges,
      bullets: bullets,
      sanitized: false, // Default, will be checked by Sanitizer
      rawPayload: rawResponse,
    );
  }
}

/// Enforces Lexicon Policy by sanitizing output.
class LexiconSanitizer {
  static const List<String> _bannedPhrases = [
    "guaranteed",
    "promise",
    "risk-free",
    "sure thing",
    "buy now",
    "sell now",
    "winning",
    "moon",
    "lambo"
  ];

  static StandardEnvelope apply(StandardEnvelope envelope) {
    bool dirty = false;
    List<String> safeBullets = [];

    for (final bullet in envelope.bullets) {
      final lower = bullet.toLowerCase();
      bool banned = false;
      for (final phrase in _bannedPhrases) {
        if (lower.contains(phrase)) {
          banned = true;
          dirty = true;
          break;
        }
      }
      if (banned) {
        safeBullets.add("N/A — phrasing blocked by Lexicon Guard");
      } else {
        safeBullets.add(bullet);
      }
    }

    if (dirty) {
      return StandardEnvelope(
        status: envelope.status,
        asOfUtc: envelope.asOfUtc,
        source: envelope.source,
        confidenceBadges: envelope.confidenceBadges,
        bullets: safeBullets,
        sanitized: true,
        sanitizationReason: SanitizationReason.bannedPhraseDetected,
        rawPayload: envelope.rawPayload,
      );
    }

    return envelope;
  }
}
