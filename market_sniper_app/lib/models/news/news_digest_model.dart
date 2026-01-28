enum DigestFreshness { live, stale, delayed, offline, demo }

enum DigestSource { pipeline, cache, offline }

enum DigestImpact { high, medium, low }

class NewsDigestItem {
  final String id;
  final String title;
  final String source;
  final DateTime publishedUtc;
  final DigestImpact impact;
  final String summaryBrief; // Max 200 chars
  final String summaryExpand; // Max 600 chars
  final List<String> symbols; // D47.HF14: For watchlist matching
  final String? rankingReason; // D47.HF14: Debug/Explainability

  const NewsDigestItem({
    required this.id,
    required this.title,
    required this.source,
    required this.publishedUtc,
    required this.impact,
    required this.summaryBrief,
    required this.summaryExpand,
    this.symbols = const [], // Default empty to avoid breaking legacy
    this.rankingReason,
  });
}

class NewsDigestViewModel {
  final DigestFreshness freshness;
  final DigestSource source;
  final DateTime asOfUtc;
  final List<NewsDigestItem> items; // Max 8

  const NewsDigestViewModel({
    required this.freshness,
    required this.source,
    required this.asOfUtc,
    required this.items,
  });

  static NewsDigestViewModel offline() {
    return NewsDigestViewModel(
      freshness: DigestFreshness.offline,
      source: DigestSource.offline,
      asOfUtc: DateTime.now().toUtc(),
      items: [],
    );
  }
}
